// The semiring laws on the catalog's operands (SR-008 – SR-207, and from SR-361 one triple per
// other scalar: fixed-width integers, Float, Float16): ⊕ associative and commutative, zero its
// identity, ⊗ associative with identity one, zero annihilating, ⊗ distributing from both sides,
// ⊗ commutative (true of all four, not required); selectivity and idempotence; and the natural
// order, a < b when a ⊕ b == a != b, with zero the worst element.
// Generated from cases.md by swiftgen.py; see README.md.

import Semirings
import Testing

@Suite("Semirings: laws and the natural order")
struct SemiringLawTests {
    @Test("SR-008 ⊕ is associative (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr008() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both -2
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let c = TropicalSemiring<Int>(7)
        let lhs: TropicalSemiring<Int> = a.plus(b).plus(c)
        let rhs: TropicalSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -2 && rhs.value == -2)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: TropicalSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-009 ⊕ is associative (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr009() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 0
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let c = TropicalSemiring<Int>(0)
        let lhs: TropicalSemiring<Int> = a.plus(b).plus(c)
        let rhs: TropicalSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: TropicalSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-010 ⊕ is associative (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr010() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both -4
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let c = TropicalSemiring<Int>(Int.max)
        let lhs: TropicalSemiring<Int> = a.plus(b).plus(c)
        let rhs: TropicalSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: TropicalSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-011 ⊕ is commutative (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr011() {
        // a ⊕ b == b ⊕ a → both -2
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let lhs: TropicalSemiring<Int> = a.plus(b)
        let rhs: TropicalSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -2 && rhs.value == -2)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊕ b
        let rhsOperators: TropicalSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-012 ⊕ is commutative (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr012() {
        // a ⊕ b == b ⊕ a → both 5
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let lhs: TropicalSemiring<Int> = a.plus(b)
        let rhs: TropicalSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊕ b
        let rhsOperators: TropicalSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-013 ⊕ is commutative (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr013() {
        // a ⊕ b == b ⊕ a → both -4
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let lhs: TropicalSemiring<Int> = a.plus(b)
        let rhs: TropicalSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊕ b
        let rhsOperators: TropicalSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-014 zero is ⊕'s identity (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr014() {
        // a ⊕ .zero == a → both 3
        let a = TropicalSemiring<Int>(3)
        let lhs: TropicalSemiring<Int> = a.plus(TropicalSemiring<Int>.zero)
        let rhs: TropicalSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊕ .zero
        let rhsOperators: TropicalSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-015 zero is ⊕'s identity (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr015() {
        // a ⊕ .zero == a → both 5
        let a = TropicalSemiring<Int>(5)
        let lhs: TropicalSemiring<Int> = a.plus(TropicalSemiring<Int>.zero)
        let rhs: TropicalSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊕ .zero
        let rhsOperators: TropicalSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-016 zero is ⊕'s identity (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr016() {
        // a ⊕ .zero == a → both -4
        let a = TropicalSemiring<Int>(-4)
        let lhs: TropicalSemiring<Int> = a.plus(TropicalSemiring<Int>.zero)
        let rhs: TropicalSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊕ .zero
        let rhsOperators: TropicalSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-017 ⊗ is associative (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr017() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 8
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let c = TropicalSemiring<Int>(7)
        let lhs: TropicalSemiring<Int> = a.times(b).times(c)
        let rhs: TropicalSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 8 && rhs.value == 8)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-018 ⊗ is associative (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr018() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int.max
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let c = TropicalSemiring<Int>(0)
        let lhs: TropicalSemiring<Int> = a.times(b).times(c)
        let rhs: TropicalSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-019 ⊗ is associative (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr019() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int.max
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let c = TropicalSemiring<Int>(Int.max)
        let lhs: TropicalSemiring<Int> = a.times(b).times(c)
        let rhs: TropicalSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-020 one is ⊗'s identity (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr020() {
        // .one ⊗ a == a ⊗ .one → both 3
        let a = TropicalSemiring<Int>(3)
        let lhs: TropicalSemiring<Int> = TropicalSemiring<Int>.one.times(a)
        let rhs: TropicalSemiring<Int> = a.times(TropicalSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = .one ⊗ a
        let rhsOperators: TropicalSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-021 one is ⊗'s identity (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr021() {
        // .one ⊗ a == a ⊗ .one → both 5
        let a = TropicalSemiring<Int>(5)
        let lhs: TropicalSemiring<Int> = TropicalSemiring<Int>.one.times(a)
        let rhs: TropicalSemiring<Int> = a.times(TropicalSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = .one ⊗ a
        let rhsOperators: TropicalSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-022 one is ⊗'s identity (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr022() {
        // .one ⊗ a == a ⊗ .one → both -4
        let a = TropicalSemiring<Int>(-4)
        let lhs: TropicalSemiring<Int> = TropicalSemiring<Int>.one.times(a)
        let rhs: TropicalSemiring<Int> = a.times(TropicalSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = .one ⊗ a
        let rhsOperators: TropicalSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-023 zero annihilates (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr023() {
        // .zero ⊗ a == a ⊗ .zero → both Int.max
        let a = TropicalSemiring<Int>(3)
        let lhs: TropicalSemiring<Int> = TropicalSemiring<Int>.zero.times(a)
        let rhs: TropicalSemiring<Int> = a.times(TropicalSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-024 zero annihilates (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr024() {
        // .zero ⊗ a == a ⊗ .zero → both Int.max
        let a = TropicalSemiring<Int>(5)
        let lhs: TropicalSemiring<Int> = TropicalSemiring<Int>.zero.times(a)
        let rhs: TropicalSemiring<Int> = a.times(TropicalSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-025 zero annihilates (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr025() {
        // .zero ⊗ a == a ⊗ .zero → both Int.max
        let a = TropicalSemiring<Int>(-4)
        let lhs: TropicalSemiring<Int> = TropicalSemiring<Int>.zero.times(a)
        let rhs: TropicalSemiring<Int> = a.times(TropicalSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-026 ⊗ distributes over ⊕ from the left (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr026() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 1
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let c = TropicalSemiring<Int>(7)
        let lhs: TropicalSemiring<Int> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1 && rhs.value == 1)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-027 ⊗ distributes over ⊕ from the left (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr027() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 5
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let c = TropicalSemiring<Int>(0)
        let lhs: TropicalSemiring<Int> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-028 ⊗ distributes over ⊕ from the left (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr028() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both -8
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let c = TropicalSemiring<Int>(Int.max)
        let lhs: TropicalSemiring<Int> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -8 && rhs.value == -8)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-029 ⊗ distributes over ⊕ from the right (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr029() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 5
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let c = TropicalSemiring<Int>(7)
        let lhs: TropicalSemiring<Int> = a.plus(b).times(c)
        let rhs: TropicalSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-030 ⊗ distributes over ⊕ from the right (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr030() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 5
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let c = TropicalSemiring<Int>(0)
        let lhs: TropicalSemiring<Int> = a.plus(b).times(c)
        let rhs: TropicalSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-031 ⊗ distributes over ⊕ from the right (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr031() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both Int.max
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let c = TropicalSemiring<Int>(Int.max)
        let lhs: TropicalSemiring<Int> = a.plus(b).times(c)
        let rhs: TropicalSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-032 ⊗ is commutative (not a requirement) (TropicalSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr032() {
        // a ⊗ b == b ⊗ a → both 1
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let lhs: TropicalSemiring<Int> = a.times(b)
        let rhs: TropicalSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1 && rhs.value == 1)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊗ b
        let rhsOperators: TropicalSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-033 ⊗ is commutative (not a requirement) (TropicalSemiring<Int>: a = 5, b = Int.max, c = 0)")
    func sr033() {
        // a ⊗ b == b ⊗ a → both Int.max
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let lhs: TropicalSemiring<Int> = a.times(b)
        let rhs: TropicalSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊗ b
        let rhsOperators: TropicalSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-034 ⊗ is commutative (not a requirement) (TropicalSemiring<Int>: a = -4, b = -4, c = Int.max)")
    func sr034() {
        // a ⊗ b == b ⊗ a → both -8
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let lhs: TropicalSemiring<Int> = a.times(b)
        let rhs: TropicalSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -8 && rhs.value == -8)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int> = a ⊗ b
        let rhsOperators: TropicalSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-035 selective: a ⊕ b is the better by < (TropicalSemiring<Int>: a = 3, b = -2)")
    func sr035() {
        // a ⊕ b == (b < a ? b : a) → true (-2)
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == -2)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-036 idempotent (TropicalSemiring<Int>: a = 3)")
    func sr036() {
        // a ⊕ a == a → true (a ⊕ a = 3)
        let a = TropicalSemiring<Int>(3)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 3)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-037 selective: a ⊕ b is the better by < (TropicalSemiring<Int>: a = 5, b = Int.max)")
    func sr037() {
        // a ⊕ b == (b < a ? b : a) → true (5)
        let a = TropicalSemiring<Int>(5)
        let b = TropicalSemiring<Int>(Int.max)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-038 idempotent (TropicalSemiring<Int>: a = 5)")
    func sr038() {
        // a ⊕ a == a → true (a ⊕ a = 5)
        let a = TropicalSemiring<Int>(5)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 5)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-039 selective: a ⊕ b is the better by < (TropicalSemiring<Int>: a = -4, b = -4)")
    func sr039() {
        // a ⊕ b == (b < a ? b : a) → true (-4)
        let a = TropicalSemiring<Int>(-4)
        let b = TropicalSemiring<Int>(-4)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == -4)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-040 idempotent (TropicalSemiring<Int>: a = -4)")
    func sr040() {
        // a ⊕ a == a → true (a ⊕ a = -4)
        let a = TropicalSemiring<Int>(-4)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == -4)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-041 the natural order: < is ‘better’ (TropicalSemiring<Int>: a = 3, b = -2)")
    func sr041() {
        // a < b → false
        let a = TropicalSemiring<Int>(3)
        let b = TropicalSemiring<Int>(-2)
        #expect(!(a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect((b < a) && a != b)
    }

    @Test("SR-042 zero is the greatest (worst) element (TropicalSemiring<Int>: a = 3)")
    func sr042() {
        // a < .zero || a == .zero → true
        let a = TropicalSemiring<Int>(3)
        #expect(a < .zero || a == .zero)
        #expect(!(TropicalSemiring<Int>.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-043 ⊕ is associative (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr043() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both -2.25
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let c = TropicalSemiring<Double>(4.0)
        let lhs: TropicalSemiring<Double> = a.plus(b).plus(c)
        let rhs: TropicalSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -2.25 && rhs.value == -2.25)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: TropicalSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-044 ⊕ is associative (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr044() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both -3.0
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let c = TropicalSemiring<Double>(-3.0)
        let lhs: TropicalSemiring<Double> = a.plus(b).plus(c)
        let rhs: TropicalSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -3.0 && rhs.value == -3.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: TropicalSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-045 ⊕ is associative (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr045() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 2.0
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let c = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = a.plus(b).plus(c)
        let rhs: TropicalSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 2.0 && rhs.value == 2.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: TropicalSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-046 ⊕ is commutative (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr046() {
        // a ⊕ b == b ⊕ a → both -2.25
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let lhs: TropicalSemiring<Double> = a.plus(b)
        let rhs: TropicalSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -2.25 && rhs.value == -2.25)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊕ b
        let rhsOperators: TropicalSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-047 ⊕ is commutative (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr047() {
        // a ⊕ b == b ⊕ a → both 0.5
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let lhs: TropicalSemiring<Double> = a.plus(b)
        let rhs: TropicalSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊕ b
        let rhsOperators: TropicalSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-048 ⊕ is commutative (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr048() {
        // a ⊕ b == b ⊕ a → both 2.0
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let lhs: TropicalSemiring<Double> = a.plus(b)
        let rhs: TropicalSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 2.0 && rhs.value == 2.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊕ b
        let rhsOperators: TropicalSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-049 zero is ⊕'s identity (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr049() {
        // a ⊕ .zero == a → both 1.5
        let a = TropicalSemiring<Double>(1.5)
        let lhs: TropicalSemiring<Double> = a.plus(TropicalSemiring<Double>.zero)
        let rhs: TropicalSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊕ .zero
        let rhsOperators: TropicalSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-050 zero is ⊕'s identity (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr050() {
        // a ⊕ .zero == a → both .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = a.plus(TropicalSemiring<Double>.zero)
        let rhs: TropicalSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊕ .zero
        let rhsOperators: TropicalSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-051 zero is ⊕'s identity (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr051() {
        // a ⊕ .zero == a → both 2.0
        let a = TropicalSemiring<Double>(2.0)
        let lhs: TropicalSemiring<Double> = a.plus(TropicalSemiring<Double>.zero)
        let rhs: TropicalSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 2.0 && rhs.value == 2.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊕ .zero
        let rhsOperators: TropicalSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-052 ⊗ is associative (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr052() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 3.25
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let c = TropicalSemiring<Double>(4.0)
        let lhs: TropicalSemiring<Double> = a.times(b).times(c)
        let rhs: TropicalSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3.25 && rhs.value == 3.25)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-053 ⊗ is associative (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr053() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let c = TropicalSemiring<Double>(-3.0)
        let lhs: TropicalSemiring<Double> = a.times(b).times(c)
        let rhs: TropicalSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-054 ⊗ is associative (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr054() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both .infinity
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let c = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = a.times(b).times(c)
        let rhs: TropicalSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-055 one is ⊗'s identity (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr055() {
        // .one ⊗ a == a ⊗ .one → both 1.5
        let a = TropicalSemiring<Double>(1.5)
        let lhs: TropicalSemiring<Double> = TropicalSemiring<Double>.one.times(a)
        let rhs: TropicalSemiring<Double> = a.times(TropicalSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = .one ⊗ a
        let rhsOperators: TropicalSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-056 one is ⊗'s identity (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr056() {
        // .one ⊗ a == a ⊗ .one → both .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = TropicalSemiring<Double>.one.times(a)
        let rhs: TropicalSemiring<Double> = a.times(TropicalSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = .one ⊗ a
        let rhsOperators: TropicalSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-057 one is ⊗'s identity (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr057() {
        // .one ⊗ a == a ⊗ .one → both 2.0
        let a = TropicalSemiring<Double>(2.0)
        let lhs: TropicalSemiring<Double> = TropicalSemiring<Double>.one.times(a)
        let rhs: TropicalSemiring<Double> = a.times(TropicalSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 2.0 && rhs.value == 2.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = .one ⊗ a
        let rhsOperators: TropicalSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-058 zero annihilates (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr058() {
        // .zero ⊗ a == a ⊗ .zero → both .infinity
        let a = TropicalSemiring<Double>(1.5)
        let lhs: TropicalSemiring<Double> = TropicalSemiring<Double>.zero.times(a)
        let rhs: TropicalSemiring<Double> = a.times(TropicalSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-059 zero annihilates (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr059() {
        // .zero ⊗ a == a ⊗ .zero → both .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = TropicalSemiring<Double>.zero.times(a)
        let rhs: TropicalSemiring<Double> = a.times(TropicalSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-060 zero annihilates (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr060() {
        // .zero ⊗ a == a ⊗ .zero → both .infinity
        let a = TropicalSemiring<Double>(2.0)
        let lhs: TropicalSemiring<Double> = TropicalSemiring<Double>.zero.times(a)
        let rhs: TropicalSemiring<Double> = a.times(TropicalSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-061 ⊗ distributes over ⊕ from the left (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr061() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both -0.75
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let c = TropicalSemiring<Double>(4.0)
        let lhs: TropicalSemiring<Double> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -0.75 && rhs.value == -0.75)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-062 ⊗ distributes over ⊕ from the left (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr062() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let c = TropicalSemiring<Double>(-3.0)
        let lhs: TropicalSemiring<Double> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-063 ⊗ distributes over ⊕ from the left (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr063() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 4.0
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let c = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 4.0 && rhs.value == 4.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-064 ⊗ distributes over ⊕ from the right (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr064() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 1.75
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let c = TropicalSemiring<Double>(4.0)
        let lhs: TropicalSemiring<Double> = a.plus(b).times(c)
        let rhs: TropicalSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1.75 && rhs.value == 1.75)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: TropicalSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-065 ⊗ distributes over ⊕ from the right (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr065() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both -2.5
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let c = TropicalSemiring<Double>(-3.0)
        let lhs: TropicalSemiring<Double> = a.plus(b).times(c)
        let rhs: TropicalSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -2.5 && rhs.value == -2.5)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: TropicalSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-066 ⊗ distributes over ⊕ from the right (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr066() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both .infinity
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let c = TropicalSemiring<Double>(Double.infinity)
        let lhs: TropicalSemiring<Double> = a.plus(b).times(c)
        let rhs: TropicalSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: TropicalSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-067 ⊗ is commutative (not a requirement) (TropicalSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr067() {
        // a ⊗ b == b ⊗ a → both -0.75
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let lhs: TropicalSemiring<Double> = a.times(b)
        let rhs: TropicalSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -0.75 && rhs.value == -0.75)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊗ b
        let rhsOperators: TropicalSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-068 ⊗ is commutative (not a requirement) (TropicalSemiring<Double>: a = .infinity, b = 0.5, c = -3.0)")
    func sr068() {
        // a ⊗ b == b ⊗ a → both .infinity
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let lhs: TropicalSemiring<Double> = a.times(b)
        let rhs: TropicalSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊗ b
        let rhsOperators: TropicalSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-069 ⊗ is commutative (not a requirement) (TropicalSemiring<Double>: a = 2.0, b = 2.0, c = .infinity)")
    func sr069() {
        // a ⊗ b == b ⊗ a → both 4.0
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let lhs: TropicalSemiring<Double> = a.times(b)
        let rhs: TropicalSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 4.0 && rhs.value == 4.0)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Double> = a ⊗ b
        let rhsOperators: TropicalSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-070 selective: a ⊕ b is the better by < (TropicalSemiring<Double>: a = 1.5, b = -2.25)")
    func sr070() {
        // a ⊕ b == (b < a ? b : a) → true (-2.25)
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == -2.25)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-071 idempotent (TropicalSemiring<Double>: a = 1.5)")
    func sr071() {
        // a ⊕ a == a → true (a ⊕ a = 1.5)
        let a = TropicalSemiring<Double>(1.5)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 1.5)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-072 selective: a ⊕ b is the better by < (TropicalSemiring<Double>: a = .infinity, b = 0.5)")
    func sr072() {
        // a ⊕ b == (b < a ? b : a) → true (0.5)
        let a = TropicalSemiring<Double>(Double.infinity)
        let b = TropicalSemiring<Double>(0.5)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 0.5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-073 idempotent (TropicalSemiring<Double>: a = .infinity)")
    func sr073() {
        // a ⊕ a == a → true (a ⊕ a = .infinity)
        let a = TropicalSemiring<Double>(Double.infinity)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == Double.infinity)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-074 selective: a ⊕ b is the better by < (TropicalSemiring<Double>: a = 2.0, b = 2.0)")
    func sr074() {
        // a ⊕ b == (b < a ? b : a) → true (2.0)
        let a = TropicalSemiring<Double>(2.0)
        let b = TropicalSemiring<Double>(2.0)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 2.0)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-075 idempotent (TropicalSemiring<Double>: a = 2.0)")
    func sr075() {
        // a ⊕ a == a → true (a ⊕ a = 2.0)
        let a = TropicalSemiring<Double>(2.0)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 2.0)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-076 the natural order: < is ‘better’ (TropicalSemiring<Double>: a = 1.5, b = -2.25)")
    func sr076() {
        // a < b → false
        let a = TropicalSemiring<Double>(1.5)
        let b = TropicalSemiring<Double>(-2.25)
        #expect(!(a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect((b < a) && a != b)
    }

    @Test("SR-077 zero is the greatest (worst) element (TropicalSemiring<Double>: a = 1.5)")
    func sr077() {
        // a < .zero || a == .zero → true
        let a = TropicalSemiring<Double>(1.5)
        #expect(a < .zero || a == .zero)
        #expect(!(TropicalSemiring<Double>.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-078 ⊕ is associative (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr078() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 7
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let c = BottleneckSemiring<Int>(7)
        let lhs: BottleneckSemiring<Int> = a.plus(b).plus(c)
        let rhs: BottleneckSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 7 && rhs.value == 7)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: BottleneckSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-079 ⊕ is associative (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr079() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both Int.max
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let c = BottleneckSemiring<Int>(5)
        let lhs: BottleneckSemiring<Int> = a.plus(b).plus(c)
        let rhs: BottleneckSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: BottleneckSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-080 ⊕ is associative (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr080() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 4
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let c = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = a.plus(b).plus(c)
        let rhs: BottleneckSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 4 && rhs.value == 4)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: BottleneckSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-081 ⊕ is commutative (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr081() {
        // a ⊕ b == b ⊕ a → both 3
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let lhs: BottleneckSemiring<Int> = a.plus(b)
        let rhs: BottleneckSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊕ b
        let rhsOperators: BottleneckSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-082 ⊕ is commutative (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr082() {
        // a ⊕ b == b ⊕ a → both Int.max
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let lhs: BottleneckSemiring<Int> = a.plus(b)
        let rhs: BottleneckSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.max && rhs.value == Int.max)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊕ b
        let rhsOperators: BottleneckSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-083 ⊕ is commutative (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr083() {
        // a ⊕ b == b ⊕ a → both 4
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let lhs: BottleneckSemiring<Int> = a.plus(b)
        let rhs: BottleneckSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 4 && rhs.value == 4)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊕ b
        let rhsOperators: BottleneckSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-084 zero is ⊕'s identity (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr084() {
        // a ⊕ .zero == a → both 3
        let a = BottleneckSemiring<Int>(3)
        let lhs: BottleneckSemiring<Int> = a.plus(BottleneckSemiring<Int>.zero)
        let rhs: BottleneckSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊕ .zero
        let rhsOperators: BottleneckSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-085 zero is ⊕'s identity (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr085() {
        // a ⊕ .zero == a → both Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = a.plus(BottleneckSemiring<Int>.zero)
        let rhs: BottleneckSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊕ .zero
        let rhsOperators: BottleneckSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-086 zero is ⊕'s identity (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr086() {
        // a ⊕ .zero == a → both 4
        let a = BottleneckSemiring<Int>(4)
        let lhs: BottleneckSemiring<Int> = a.plus(BottleneckSemiring<Int>.zero)
        let rhs: BottleneckSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 4 && rhs.value == 4)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊕ .zero
        let rhsOperators: BottleneckSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-087 ⊗ is associative (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr087() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -2
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let c = BottleneckSemiring<Int>(7)
        let lhs: BottleneckSemiring<Int> = a.times(b).times(c)
        let rhs: BottleneckSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -2 && rhs.value == -2)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-088 ⊗ is associative (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr088() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let c = BottleneckSemiring<Int>(5)
        let lhs: BottleneckSemiring<Int> = a.times(b).times(c)
        let rhs: BottleneckSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-089 ⊗ is associative (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr089() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int.min
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let c = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = a.times(b).times(c)
        let rhs: BottleneckSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-090 one is ⊗'s identity (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr090() {
        // .one ⊗ a == a ⊗ .one → both 3
        let a = BottleneckSemiring<Int>(3)
        let lhs: BottleneckSemiring<Int> = BottleneckSemiring<Int>.one.times(a)
        let rhs: BottleneckSemiring<Int> = a.times(BottleneckSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = .one ⊗ a
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-091 one is ⊗'s identity (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr091() {
        // .one ⊗ a == a ⊗ .one → both Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = BottleneckSemiring<Int>.one.times(a)
        let rhs: BottleneckSemiring<Int> = a.times(BottleneckSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = .one ⊗ a
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-092 one is ⊗'s identity (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr092() {
        // .one ⊗ a == a ⊗ .one → both 4
        let a = BottleneckSemiring<Int>(4)
        let lhs: BottleneckSemiring<Int> = BottleneckSemiring<Int>.one.times(a)
        let rhs: BottleneckSemiring<Int> = a.times(BottleneckSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 4 && rhs.value == 4)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = .one ⊗ a
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-093 zero annihilates (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr093() {
        // .zero ⊗ a == a ⊗ .zero → both Int.min
        let a = BottleneckSemiring<Int>(3)
        let lhs: BottleneckSemiring<Int> = BottleneckSemiring<Int>.zero.times(a)
        let rhs: BottleneckSemiring<Int> = a.times(BottleneckSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-094 zero annihilates (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr094() {
        // .zero ⊗ a == a ⊗ .zero → both Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = BottleneckSemiring<Int>.zero.times(a)
        let rhs: BottleneckSemiring<Int> = a.times(BottleneckSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-095 zero annihilates (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr095() {
        // .zero ⊗ a == a ⊗ .zero → both Int.min
        let a = BottleneckSemiring<Int>(4)
        let lhs: BottleneckSemiring<Int> = BottleneckSemiring<Int>.zero.times(a)
        let rhs: BottleneckSemiring<Int> = a.times(BottleneckSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-096 ⊗ distributes over ⊕ from the left (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr096() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 3
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let c = BottleneckSemiring<Int>(7)
        let lhs: BottleneckSemiring<Int> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-097 ⊗ distributes over ⊕ from the left (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr097() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let c = BottleneckSemiring<Int>(5)
        let lhs: BottleneckSemiring<Int> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-098 ⊗ distributes over ⊕ from the left (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr098() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 4
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let c = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 4 && rhs.value == 4)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-099 ⊗ distributes over ⊕ from the right (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr099() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 3
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let c = BottleneckSemiring<Int>(7)
        let lhs: BottleneckSemiring<Int> = a.plus(b).times(c)
        let rhs: BottleneckSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-100 ⊗ distributes over ⊕ from the right (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr100() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 5
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let c = BottleneckSemiring<Int>(5)
        let lhs: BottleneckSemiring<Int> = a.plus(b).times(c)
        let rhs: BottleneckSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-101 ⊗ distributes over ⊕ from the right (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr101() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both Int.min
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let c = BottleneckSemiring<Int>(Int.min)
        let lhs: BottleneckSemiring<Int> = a.plus(b).times(c)
        let rhs: BottleneckSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-102 ⊗ is commutative (not a requirement) (BottleneckSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr102() {
        // a ⊗ b == b ⊗ a → both -2
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let lhs: BottleneckSemiring<Int> = a.times(b)
        let rhs: BottleneckSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -2 && rhs.value == -2)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊗ b
        let rhsOperators: BottleneckSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-103 ⊗ is commutative (not a requirement) (BottleneckSemiring<Int>: a = Int.min, b = Int.max, c = 5)")
    func sr103() {
        // a ⊗ b == b ⊗ a → both Int.min
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let lhs: BottleneckSemiring<Int> = a.times(b)
        let rhs: BottleneckSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊗ b
        let rhsOperators: BottleneckSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-104 ⊗ is commutative (not a requirement) (BottleneckSemiring<Int>: a = 4, b = 4, c = Int.min)")
    func sr104() {
        // a ⊗ b == b ⊗ a → both 4
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let lhs: BottleneckSemiring<Int> = a.times(b)
        let rhs: BottleneckSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 4 && rhs.value == 4)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Int> = a ⊗ b
        let rhsOperators: BottleneckSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-105 selective: a ⊕ b is the better by < (BottleneckSemiring<Int>: a = 3, b = -2)")
    func sr105() {
        // a ⊕ b == (b < a ? b : a) → true (3)
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 3)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-106 idempotent (BottleneckSemiring<Int>: a = 3)")
    func sr106() {
        // a ⊕ a == a → true (a ⊕ a = 3)
        let a = BottleneckSemiring<Int>(3)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 3)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-107 selective: a ⊕ b is the better by < (BottleneckSemiring<Int>: a = Int.min, b = Int.max)")
    func sr107() {
        // a ⊕ b == (b < a ? b : a) → true (Int.max)
        let a = BottleneckSemiring<Int>(Int.min)
        let b = BottleneckSemiring<Int>(Int.max)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == Int.max)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-108 idempotent (BottleneckSemiring<Int>: a = Int.min)")
    func sr108() {
        // a ⊕ a == a → true (a ⊕ a = Int.min)
        let a = BottleneckSemiring<Int>(Int.min)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == Int.min)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-109 selective: a ⊕ b is the better by < (BottleneckSemiring<Int>: a = 4, b = 4)")
    func sr109() {
        // a ⊕ b == (b < a ? b : a) → true (4)
        let a = BottleneckSemiring<Int>(4)
        let b = BottleneckSemiring<Int>(4)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 4)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-110 idempotent (BottleneckSemiring<Int>: a = 4)")
    func sr110() {
        // a ⊕ a == a → true (a ⊕ a = 4)
        let a = BottleneckSemiring<Int>(4)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 4)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-111 the natural order: < is ‘better’ (BottleneckSemiring<Int>: a = 3, b = -2)")
    func sr111() {
        // a < b → true
        let a = BottleneckSemiring<Int>(3)
        let b = BottleneckSemiring<Int>(-2)
        #expect((a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect(!(b < a) && a != b)
    }

    @Test("SR-112 zero is the greatest (worst) element (BottleneckSemiring<Int>: a = 3)")
    func sr112() {
        // a < .zero || a == .zero → true
        let a = BottleneckSemiring<Int>(3)
        #expect(a < .zero || a == .zero)
        #expect(!(BottleneckSemiring<Int>.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-113 ⊕ is associative (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr113() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 4.0
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let c = BottleneckSemiring<Double>(4.0)
        let lhs: BottleneckSemiring<Double> = a.plus(b).plus(c)
        let rhs: BottleneckSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 4.0 && rhs.value == 4.0)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: BottleneckSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-114 ⊕ is associative (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr114() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both .infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let c = BottleneckSemiring<Double>(0.5)
        let lhs: BottleneckSemiring<Double> = a.plus(b).plus(c)
        let rhs: BottleneckSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: BottleneckSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-115 ⊕ is commutative (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr115() {
        // a ⊕ b == b ⊕ a → both 1.5
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let lhs: BottleneckSemiring<Double> = a.plus(b)
        let rhs: BottleneckSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊕ b
        let rhsOperators: BottleneckSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-116 ⊕ is commutative (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr116() {
        // a ⊕ b == b ⊕ a → both .infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let lhs: BottleneckSemiring<Double> = a.plus(b)
        let rhs: BottleneckSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == Double.infinity && rhs.value == Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊕ b
        let rhsOperators: BottleneckSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-117 zero is ⊕'s identity (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr117() {
        // a ⊕ .zero == a → both 1.5
        let a = BottleneckSemiring<Double>(1.5)
        let lhs: BottleneckSemiring<Double> = a.plus(BottleneckSemiring<Double>.zero)
        let rhs: BottleneckSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊕ .zero
        let rhsOperators: BottleneckSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-118 zero is ⊕'s identity (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr118() {
        // a ⊕ .zero == a → both -.infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let lhs: BottleneckSemiring<Double> = a.plus(BottleneckSemiring<Double>.zero)
        let rhs: BottleneckSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊕ .zero
        let rhsOperators: BottleneckSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-119 ⊗ is associative (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr119() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -2.25
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let c = BottleneckSemiring<Double>(4.0)
        let lhs: BottleneckSemiring<Double> = a.times(b).times(c)
        let rhs: BottleneckSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -2.25 && rhs.value == -2.25)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-120 ⊗ is associative (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr120() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -.infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let c = BottleneckSemiring<Double>(0.5)
        let lhs: BottleneckSemiring<Double> = a.times(b).times(c)
        let rhs: BottleneckSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-121 one is ⊗'s identity (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr121() {
        // .one ⊗ a == a ⊗ .one → both 1.5
        let a = BottleneckSemiring<Double>(1.5)
        let lhs: BottleneckSemiring<Double> = BottleneckSemiring<Double>.one.times(a)
        let rhs: BottleneckSemiring<Double> = a.times(BottleneckSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = .one ⊗ a
        let rhsOperators: BottleneckSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-122 one is ⊗'s identity (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr122() {
        // .one ⊗ a == a ⊗ .one → both -.infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let lhs: BottleneckSemiring<Double> = BottleneckSemiring<Double>.one.times(a)
        let rhs: BottleneckSemiring<Double> = a.times(BottleneckSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = .one ⊗ a
        let rhsOperators: BottleneckSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-123 zero annihilates (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr123() {
        // .zero ⊗ a == a ⊗ .zero → both -.infinity
        let a = BottleneckSemiring<Double>(1.5)
        let lhs: BottleneckSemiring<Double> = BottleneckSemiring<Double>.zero.times(a)
        let rhs: BottleneckSemiring<Double> = a.times(BottleneckSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-124 zero annihilates (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr124() {
        // .zero ⊗ a == a ⊗ .zero → both -.infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let lhs: BottleneckSemiring<Double> = BottleneckSemiring<Double>.zero.times(a)
        let rhs: BottleneckSemiring<Double> = a.times(BottleneckSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-125 ⊗ distributes over ⊕ from the left (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr125() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 1.5
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let c = BottleneckSemiring<Double>(4.0)
        let lhs: BottleneckSemiring<Double> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-126 ⊗ distributes over ⊕ from the left (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr126() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both -.infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let c = BottleneckSemiring<Double>(0.5)
        let lhs: BottleneckSemiring<Double> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-127 ⊗ distributes over ⊕ from the right (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr127() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 1.5
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let c = BottleneckSemiring<Double>(4.0)
        let lhs: BottleneckSemiring<Double> = a.plus(b).times(c)
        let rhs: BottleneckSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-128 ⊗ distributes over ⊕ from the right (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr128() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 0.5
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let c = BottleneckSemiring<Double>(0.5)
        let lhs: BottleneckSemiring<Double> = a.plus(b).times(c)
        let rhs: BottleneckSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-129 ⊗ is commutative (not a requirement) (BottleneckSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr129() {
        // a ⊗ b == b ⊗ a → both -2.25
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let lhs: BottleneckSemiring<Double> = a.times(b)
        let rhs: BottleneckSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -2.25 && rhs.value == -2.25)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊗ b
        let rhsOperators: BottleneckSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-130 ⊗ is commutative (not a requirement) (BottleneckSemiring<Double>: a = -.infinity, b = .infinity, c = 0.5)")
    func sr130() {
        // a ⊗ b == b ⊗ a → both -.infinity
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let lhs: BottleneckSemiring<Double> = a.times(b)
        let rhs: BottleneckSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Double> = a ⊗ b
        let rhsOperators: BottleneckSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-131 selective: a ⊕ b is the better by < (BottleneckSemiring<Double>: a = 1.5, b = -2.25)")
    func sr131() {
        // a ⊕ b == (b < a ? b : a) → true (1.5)
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 1.5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-132 idempotent (BottleneckSemiring<Double>: a = 1.5)")
    func sr132() {
        // a ⊕ a == a → true (a ⊕ a = 1.5)
        let a = BottleneckSemiring<Double>(1.5)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 1.5)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-133 selective: a ⊕ b is the better by < (BottleneckSemiring<Double>: a = -.infinity, b = .infinity)")
    func sr133() {
        // a ⊕ b == (b < a ? b : a) → true (.infinity)
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let b = BottleneckSemiring<Double>(Double.infinity)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == Double.infinity)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-134 idempotent (BottleneckSemiring<Double>: a = -.infinity)")
    func sr134() {
        // a ⊕ a == a → true (a ⊕ a = -.infinity)
        let a = BottleneckSemiring<Double>(-Double.infinity)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == -Double.infinity)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-135 the natural order: < is ‘better’ (BottleneckSemiring<Double>: a = 1.5, b = -2.25)")
    func sr135() {
        // a < b → true
        let a = BottleneckSemiring<Double>(1.5)
        let b = BottleneckSemiring<Double>(-2.25)
        #expect((a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect(!(b < a) && a != b)
    }

    @Test("SR-136 zero is the greatest (worst) element (BottleneckSemiring<Double>: a = 1.5)")
    func sr136() {
        // a < .zero || a == .zero → true
        let a = BottleneckSemiring<Double>(1.5)
        #expect(a < .zero || a == .zero)
        #expect(!(BottleneckSemiring<Double>.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-137 ⊕ is associative (BooleanSemiring: a = true, b = false, c = true)")
    func sr137() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both true
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.plus(b).plus(c)
        let rhs: BooleanSemiring = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = (a ⊕ b) ⊕ c
        let rhsOperators: BooleanSemiring = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-138 ⊕ is associative (BooleanSemiring: a = false, b = false, c = true)")
    func sr138() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both true
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.plus(b).plus(c)
        let rhs: BooleanSemiring = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = (a ⊕ b) ⊕ c
        let rhsOperators: BooleanSemiring = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-139 ⊕ is commutative (BooleanSemiring: a = true, b = false, c = true)")
    func sr139() {
        // a ⊕ b == b ⊕ a → both true
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let lhs: BooleanSemiring = a.plus(b)
        let rhs: BooleanSemiring = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊕ b
        let rhsOperators: BooleanSemiring = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-140 ⊕ is commutative (BooleanSemiring: a = false, b = false, c = true)")
    func sr140() {
        // a ⊕ b == b ⊕ a → both false
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let lhs: BooleanSemiring = a.plus(b)
        let rhs: BooleanSemiring = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊕ b
        let rhsOperators: BooleanSemiring = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-141 zero is ⊕'s identity (BooleanSemiring: a = true, b = false, c = true)")
    func sr141() {
        // a ⊕ .zero == a → both true
        let a = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.plus(BooleanSemiring.zero)
        let rhs: BooleanSemiring = a
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊕ .zero
        let rhsOperators: BooleanSemiring = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-142 zero is ⊕'s identity (BooleanSemiring: a = false, b = false, c = true)")
    func sr142() {
        // a ⊕ .zero == a → both false
        let a = BooleanSemiring(false)
        let lhs: BooleanSemiring = a.plus(BooleanSemiring.zero)
        let rhs: BooleanSemiring = a
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊕ .zero
        let rhsOperators: BooleanSemiring = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-143 ⊗ is associative (BooleanSemiring: a = true, b = false, c = true)")
    func sr143() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both false
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.times(b).times(c)
        let rhs: BooleanSemiring = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = (a ⊗ b) ⊗ c
        let rhsOperators: BooleanSemiring = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-144 ⊗ is associative (BooleanSemiring: a = false, b = false, c = true)")
    func sr144() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both false
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.times(b).times(c)
        let rhs: BooleanSemiring = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = (a ⊗ b) ⊗ c
        let rhsOperators: BooleanSemiring = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-145 one is ⊗'s identity (BooleanSemiring: a = true, b = false, c = true)")
    func sr145() {
        // .one ⊗ a == a ⊗ .one → both true
        let a = BooleanSemiring(true)
        let lhs: BooleanSemiring = BooleanSemiring.one.times(a)
        let rhs: BooleanSemiring = a.times(BooleanSemiring.one)
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = .one ⊗ a
        let rhsOperators: BooleanSemiring = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-146 one is ⊗'s identity (BooleanSemiring: a = false, b = false, c = true)")
    func sr146() {
        // .one ⊗ a == a ⊗ .one → both false
        let a = BooleanSemiring(false)
        let lhs: BooleanSemiring = BooleanSemiring.one.times(a)
        let rhs: BooleanSemiring = a.times(BooleanSemiring.one)
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = .one ⊗ a
        let rhsOperators: BooleanSemiring = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-147 zero annihilates (BooleanSemiring: a = true, b = false, c = true)")
    func sr147() {
        // .zero ⊗ a == a ⊗ .zero → both false
        let a = BooleanSemiring(true)
        let lhs: BooleanSemiring = BooleanSemiring.zero.times(a)
        let rhs: BooleanSemiring = a.times(BooleanSemiring.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = .zero ⊗ a
        let rhsOperators: BooleanSemiring = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-148 zero annihilates (BooleanSemiring: a = false, b = false, c = true)")
    func sr148() {
        // .zero ⊗ a == a ⊗ .zero → both false
        let a = BooleanSemiring(false)
        let lhs: BooleanSemiring = BooleanSemiring.zero.times(a)
        let rhs: BooleanSemiring = a.times(BooleanSemiring.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = .zero ⊗ a
        let rhsOperators: BooleanSemiring = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-149 ⊗ distributes over ⊕ from the left (BooleanSemiring: a = true, b = false, c = true)")
    func sr149() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both true
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.times(b.plus(c))
        let rhs: BooleanSemiring = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊗ (b ⊕ c)
        let rhsOperators: BooleanSemiring = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-150 ⊗ distributes over ⊕ from the left (BooleanSemiring: a = false, b = false, c = true)")
    func sr150() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both false
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.times(b.plus(c))
        let rhs: BooleanSemiring = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊗ (b ⊕ c)
        let rhsOperators: BooleanSemiring = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-151 ⊗ distributes over ⊕ from the right (BooleanSemiring: a = true, b = false, c = true)")
    func sr151() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both true
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.plus(b).times(c)
        let rhs: BooleanSemiring = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == true && rhs.value == true)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = (a ⊕ b) ⊗ c
        let rhsOperators: BooleanSemiring = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-152 ⊗ distributes over ⊕ from the right (BooleanSemiring: a = false, b = false, c = true)")
    func sr152() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both false
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let c = BooleanSemiring(true)
        let lhs: BooleanSemiring = a.plus(b).times(c)
        let rhs: BooleanSemiring = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = (a ⊕ b) ⊗ c
        let rhsOperators: BooleanSemiring = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-153 ⊗ is commutative (not a requirement) (BooleanSemiring: a = true, b = false, c = true)")
    func sr153() {
        // a ⊗ b == b ⊗ a → both false
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let lhs: BooleanSemiring = a.times(b)
        let rhs: BooleanSemiring = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊗ b
        let rhsOperators: BooleanSemiring = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-154 ⊗ is commutative (not a requirement) (BooleanSemiring: a = false, b = false, c = true)")
    func sr154() {
        // a ⊗ b == b ⊗ a → both false
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let lhs: BooleanSemiring = a.times(b)
        let rhs: BooleanSemiring = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == false && rhs.value == false)
        // The operators call the methods.
        let lhsOperators: BooleanSemiring = a ⊗ b
        let rhsOperators: BooleanSemiring = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-155 selective: a ⊕ b is the better by < (BooleanSemiring: a = true, b = false)")
    func sr155() {
        // a ⊕ b == (b < a ? b : a) → true (true)
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == true)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-156 idempotent (BooleanSemiring: a = true)")
    func sr156() {
        // a ⊕ a == a → true (a ⊕ a = true)
        let a = BooleanSemiring(true)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == true)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-157 selective: a ⊕ b is the better by < (BooleanSemiring: a = false, b = false)")
    func sr157() {
        // a ⊕ b == (b < a ? b : a) → true (false)
        let a = BooleanSemiring(false)
        let b = BooleanSemiring(false)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == false)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-158 idempotent (BooleanSemiring: a = false)")
    func sr158() {
        // a ⊕ a == a → true (a ⊕ a = false)
        let a = BooleanSemiring(false)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == false)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-159 the natural order: < is ‘better’ (BooleanSemiring: a = true, b = false)")
    func sr159() {
        // a < b → true
        let a = BooleanSemiring(true)
        let b = BooleanSemiring(false)
        #expect((a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect(!(b < a) && a != b)
    }

    @Test("SR-160 zero is the greatest (worst) element (BooleanSemiring: a = true)")
    func sr160() {
        // a < .zero || a == .zero → true
        let a = BooleanSemiring(true)
        #expect(a < .zero || a == .zero)
        #expect(!(BooleanSemiring.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-161 ⊕ is associative (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr161() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 8
        let a = CountingSemiring<Int>(3)
        let b = CountingSemiring<Int>(-2)
        let c = CountingSemiring<Int>(7)
        let lhs: CountingSemiring<Int> = a.plus(b).plus(c)
        let rhs: CountingSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 8 && rhs.value == 8)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: CountingSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-162 ⊕ is associative (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr162() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 6
        let a = CountingSemiring<Int>(0)
        let b = CountingSemiring<Int>(1)
        let c = CountingSemiring<Int>(5)
        let lhs: CountingSemiring<Int> = a.plus(b).plus(c)
        let rhs: CountingSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 6 && rhs.value == 6)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: CountingSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-163 ⊕ is associative (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr163() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 11
        let a = CountingSemiring<Int>(6)
        let b = CountingSemiring<Int>(6)
        let c = CountingSemiring<Int>(-1)
        let lhs: CountingSemiring<Int> = a.plus(b).plus(c)
        let rhs: CountingSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 11 && rhs.value == 11)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: CountingSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-164 ⊕ is commutative (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr164() {
        // a ⊕ b == b ⊕ a → both 1
        let a = CountingSemiring<Int>(3)
        let b = CountingSemiring<Int>(-2)
        let lhs: CountingSemiring<Int> = a.plus(b)
        let rhs: CountingSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1 && rhs.value == 1)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊕ b
        let rhsOperators: CountingSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-165 ⊕ is commutative (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr165() {
        // a ⊕ b == b ⊕ a → both 1
        let a = CountingSemiring<Int>(0)
        let b = CountingSemiring<Int>(1)
        let lhs: CountingSemiring<Int> = a.plus(b)
        let rhs: CountingSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1 && rhs.value == 1)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊕ b
        let rhsOperators: CountingSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-166 ⊕ is commutative (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr166() {
        // a ⊕ b == b ⊕ a → both 12
        let a = CountingSemiring<Int>(6)
        let b = CountingSemiring<Int>(6)
        let lhs: CountingSemiring<Int> = a.plus(b)
        let rhs: CountingSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 12 && rhs.value == 12)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊕ b
        let rhsOperators: CountingSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-167 zero is ⊕'s identity (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr167() {
        // a ⊕ .zero == a → both 3
        let a = CountingSemiring<Int>(3)
        let lhs: CountingSemiring<Int> = a.plus(CountingSemiring<Int>.zero)
        let rhs: CountingSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊕ .zero
        let rhsOperators: CountingSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-168 zero is ⊕'s identity (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr168() {
        // a ⊕ .zero == a → both 0
        let a = CountingSemiring<Int>(0)
        let lhs: CountingSemiring<Int> = a.plus(CountingSemiring<Int>.zero)
        let rhs: CountingSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊕ .zero
        let rhsOperators: CountingSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-169 zero is ⊕'s identity (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr169() {
        // a ⊕ .zero == a → both 6
        let a = CountingSemiring<Int>(6)
        let lhs: CountingSemiring<Int> = a.plus(CountingSemiring<Int>.zero)
        let rhs: CountingSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 6 && rhs.value == 6)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊕ .zero
        let rhsOperators: CountingSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-170 ⊗ is associative (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr170() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -42
        let a = CountingSemiring<Int>(3)
        let b = CountingSemiring<Int>(-2)
        let c = CountingSemiring<Int>(7)
        let lhs: CountingSemiring<Int> = a.times(b).times(c)
        let rhs: CountingSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -42 && rhs.value == -42)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: CountingSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-171 ⊗ is associative (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr171() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 0
        let a = CountingSemiring<Int>(0)
        let b = CountingSemiring<Int>(1)
        let c = CountingSemiring<Int>(5)
        let lhs: CountingSemiring<Int> = a.times(b).times(c)
        let rhs: CountingSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: CountingSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-172 ⊗ is associative (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr172() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -36
        let a = CountingSemiring<Int>(6)
        let b = CountingSemiring<Int>(6)
        let c = CountingSemiring<Int>(-1)
        let lhs: CountingSemiring<Int> = a.times(b).times(c)
        let rhs: CountingSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -36 && rhs.value == -36)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: CountingSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-173 one is ⊗'s identity (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr173() {
        // .one ⊗ a == a ⊗ .one → both 3
        let a = CountingSemiring<Int>(3)
        let lhs: CountingSemiring<Int> = CountingSemiring<Int>.one.times(a)
        let rhs: CountingSemiring<Int> = a.times(CountingSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = .one ⊗ a
        let rhsOperators: CountingSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-174 one is ⊗'s identity (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr174() {
        // .one ⊗ a == a ⊗ .one → both 0
        let a = CountingSemiring<Int>(0)
        let lhs: CountingSemiring<Int> = CountingSemiring<Int>.one.times(a)
        let rhs: CountingSemiring<Int> = a.times(CountingSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = .one ⊗ a
        let rhsOperators: CountingSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-175 one is ⊗'s identity (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr175() {
        // .one ⊗ a == a ⊗ .one → both 6
        let a = CountingSemiring<Int>(6)
        let lhs: CountingSemiring<Int> = CountingSemiring<Int>.one.times(a)
        let rhs: CountingSemiring<Int> = a.times(CountingSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 6 && rhs.value == 6)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = .one ⊗ a
        let rhsOperators: CountingSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-176 zero annihilates (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr176() {
        // .zero ⊗ a == a ⊗ .zero → both 0
        let a = CountingSemiring<Int>(3)
        let lhs: CountingSemiring<Int> = CountingSemiring<Int>.zero.times(a)
        let rhs: CountingSemiring<Int> = a.times(CountingSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = .zero ⊗ a
        let rhsOperators: CountingSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-177 zero annihilates (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr177() {
        // .zero ⊗ a == a ⊗ .zero → both 0
        let a = CountingSemiring<Int>(0)
        let lhs: CountingSemiring<Int> = CountingSemiring<Int>.zero.times(a)
        let rhs: CountingSemiring<Int> = a.times(CountingSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = .zero ⊗ a
        let rhsOperators: CountingSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-178 zero annihilates (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr178() {
        // .zero ⊗ a == a ⊗ .zero → both 0
        let a = CountingSemiring<Int>(6)
        let lhs: CountingSemiring<Int> = CountingSemiring<Int>.zero.times(a)
        let rhs: CountingSemiring<Int> = a.times(CountingSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = .zero ⊗ a
        let rhsOperators: CountingSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-179 ⊗ distributes over ⊕ from the left (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr179() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 15
        let a = CountingSemiring<Int>(3)
        let b = CountingSemiring<Int>(-2)
        let c = CountingSemiring<Int>(7)
        let lhs: CountingSemiring<Int> = a.times(b.plus(c))
        let rhs: CountingSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 15 && rhs.value == 15)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: CountingSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-180 ⊗ distributes over ⊕ from the left (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr180() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 0
        let a = CountingSemiring<Int>(0)
        let b = CountingSemiring<Int>(1)
        let c = CountingSemiring<Int>(5)
        let lhs: CountingSemiring<Int> = a.times(b.plus(c))
        let rhs: CountingSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: CountingSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-181 ⊗ distributes over ⊕ from the left (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr181() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 30
        let a = CountingSemiring<Int>(6)
        let b = CountingSemiring<Int>(6)
        let c = CountingSemiring<Int>(-1)
        let lhs: CountingSemiring<Int> = a.times(b.plus(c))
        let rhs: CountingSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 30 && rhs.value == 30)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: CountingSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-182 ⊗ distributes over ⊕ from the right (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr182() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 7
        let a = CountingSemiring<Int>(3)
        let b = CountingSemiring<Int>(-2)
        let c = CountingSemiring<Int>(7)
        let lhs: CountingSemiring<Int> = a.plus(b).times(c)
        let rhs: CountingSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 7 && rhs.value == 7)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: CountingSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-183 ⊗ distributes over ⊕ from the right (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr183() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 5
        let a = CountingSemiring<Int>(0)
        let b = CountingSemiring<Int>(1)
        let c = CountingSemiring<Int>(5)
        let lhs: CountingSemiring<Int> = a.plus(b).times(c)
        let rhs: CountingSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: CountingSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-184 ⊗ distributes over ⊕ from the right (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr184() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both -12
        let a = CountingSemiring<Int>(6)
        let b = CountingSemiring<Int>(6)
        let c = CountingSemiring<Int>(-1)
        let lhs: CountingSemiring<Int> = a.plus(b).times(c)
        let rhs: CountingSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -12 && rhs.value == -12)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: CountingSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-185 ⊗ is commutative (not a requirement) (CountingSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr185() {
        // a ⊗ b == b ⊗ a → both -6
        let a = CountingSemiring<Int>(3)
        let b = CountingSemiring<Int>(-2)
        let lhs: CountingSemiring<Int> = a.times(b)
        let rhs: CountingSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -6 && rhs.value == -6)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊗ b
        let rhsOperators: CountingSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-186 ⊗ is commutative (not a requirement) (CountingSemiring<Int>: a = 0, b = 1, c = 5)")
    func sr186() {
        // a ⊗ b == b ⊗ a → both 0
        let a = CountingSemiring<Int>(0)
        let b = CountingSemiring<Int>(1)
        let lhs: CountingSemiring<Int> = a.times(b)
        let rhs: CountingSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊗ b
        let rhsOperators: CountingSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-187 ⊗ is commutative (not a requirement) (CountingSemiring<Int>: a = 6, b = 6, c = -1)")
    func sr187() {
        // a ⊗ b == b ⊗ a → both 36
        let a = CountingSemiring<Int>(6)
        let b = CountingSemiring<Int>(6)
        let lhs: CountingSemiring<Int> = a.times(b)
        let rhs: CountingSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 36 && rhs.value == 36)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Int> = a ⊗ b
        let rhsOperators: CountingSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-188 not idempotent (CountingSemiring<Int>: a = 3)")
    func sr188() {
        // a ⊕ a == a → false (a ⊕ a = 6)
        let a = CountingSemiring<Int>(3)
        let sum = a.plus(a)
        #expect(sum != a)
        #expect(sum.value == 6)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-189 ⊕ is associative (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr189() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 3.25
        let a = CountingSemiring<Double>(1.5)
        let b = CountingSemiring<Double>(-2.25)
        let c = CountingSemiring<Double>(4.0)
        let lhs: CountingSemiring<Double> = a.plus(b).plus(c)
        let rhs: CountingSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3.25 && rhs.value == 3.25)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: CountingSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-190 ⊕ is associative (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr190() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 1.5
        let a = CountingSemiring<Double>(0.0)
        let b = CountingSemiring<Double>(1.0)
        let c = CountingSemiring<Double>(0.5)
        let lhs: CountingSemiring<Double> = a.plus(b).plus(c)
        let rhs: CountingSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: CountingSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-191 ⊕ is commutative (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr191() {
        // a ⊕ b == b ⊕ a → both -0.75
        let a = CountingSemiring<Double>(1.5)
        let b = CountingSemiring<Double>(-2.25)
        let lhs: CountingSemiring<Double> = a.plus(b)
        let rhs: CountingSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -0.75 && rhs.value == -0.75)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊕ b
        let rhsOperators: CountingSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-192 ⊕ is commutative (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr192() {
        // a ⊕ b == b ⊕ a → both 1.0
        let a = CountingSemiring<Double>(0.0)
        let b = CountingSemiring<Double>(1.0)
        let lhs: CountingSemiring<Double> = a.plus(b)
        let rhs: CountingSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.0 && rhs.value == 1.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊕ b
        let rhsOperators: CountingSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-193 zero is ⊕'s identity (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr193() {
        // a ⊕ .zero == a → both 1.5
        let a = CountingSemiring<Double>(1.5)
        let lhs: CountingSemiring<Double> = a.plus(CountingSemiring<Double>.zero)
        let rhs: CountingSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊕ .zero
        let rhsOperators: CountingSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-194 zero is ⊕'s identity (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr194() {
        // a ⊕ .zero == a → both 0.0
        let a = CountingSemiring<Double>(0.0)
        let lhs: CountingSemiring<Double> = a.plus(CountingSemiring<Double>.zero)
        let rhs: CountingSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊕ .zero
        let rhsOperators: CountingSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-195 ⊗ is associative (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr195() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -13.5
        let a = CountingSemiring<Double>(1.5)
        let b = CountingSemiring<Double>(-2.25)
        let c = CountingSemiring<Double>(4.0)
        let lhs: CountingSemiring<Double> = a.times(b).times(c)
        let rhs: CountingSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -13.5 && rhs.value == -13.5)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: CountingSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-196 ⊗ is associative (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr196() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 0.0
        let a = CountingSemiring<Double>(0.0)
        let b = CountingSemiring<Double>(1.0)
        let c = CountingSemiring<Double>(0.5)
        let lhs: CountingSemiring<Double> = a.times(b).times(c)
        let rhs: CountingSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: CountingSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-197 one is ⊗'s identity (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr197() {
        // .one ⊗ a == a ⊗ .one → both 1.5
        let a = CountingSemiring<Double>(1.5)
        let lhs: CountingSemiring<Double> = CountingSemiring<Double>.one.times(a)
        let rhs: CountingSemiring<Double> = a.times(CountingSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = .one ⊗ a
        let rhsOperators: CountingSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-198 one is ⊗'s identity (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr198() {
        // .one ⊗ a == a ⊗ .one → both 0.0
        let a = CountingSemiring<Double>(0.0)
        let lhs: CountingSemiring<Double> = CountingSemiring<Double>.one.times(a)
        let rhs: CountingSemiring<Double> = a.times(CountingSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = .one ⊗ a
        let rhsOperators: CountingSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-199 zero annihilates (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr199() {
        // .zero ⊗ a == a ⊗ .zero → both 0.0
        let a = CountingSemiring<Double>(1.5)
        let lhs: CountingSemiring<Double> = CountingSemiring<Double>.zero.times(a)
        let rhs: CountingSemiring<Double> = a.times(CountingSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = .zero ⊗ a
        let rhsOperators: CountingSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-200 zero annihilates (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr200() {
        // .zero ⊗ a == a ⊗ .zero → both 0.0
        let a = CountingSemiring<Double>(0.0)
        let lhs: CountingSemiring<Double> = CountingSemiring<Double>.zero.times(a)
        let rhs: CountingSemiring<Double> = a.times(CountingSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = .zero ⊗ a
        let rhsOperators: CountingSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-201 ⊗ distributes over ⊕ from the left (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr201() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 2.625
        let a = CountingSemiring<Double>(1.5)
        let b = CountingSemiring<Double>(-2.25)
        let c = CountingSemiring<Double>(4.0)
        let lhs: CountingSemiring<Double> = a.times(b.plus(c))
        let rhs: CountingSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 2.625 && rhs.value == 2.625)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: CountingSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-202 ⊗ distributes over ⊕ from the left (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr202() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 0.0
        let a = CountingSemiring<Double>(0.0)
        let b = CountingSemiring<Double>(1.0)
        let c = CountingSemiring<Double>(0.5)
        let lhs: CountingSemiring<Double> = a.times(b.plus(c))
        let rhs: CountingSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: CountingSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-203 ⊗ distributes over ⊕ from the right (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr203() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both -3.0
        let a = CountingSemiring<Double>(1.5)
        let b = CountingSemiring<Double>(-2.25)
        let c = CountingSemiring<Double>(4.0)
        let lhs: CountingSemiring<Double> = a.plus(b).times(c)
        let rhs: CountingSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -3.0 && rhs.value == -3.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: CountingSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-204 ⊗ distributes over ⊕ from the right (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr204() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 0.5
        let a = CountingSemiring<Double>(0.0)
        let b = CountingSemiring<Double>(1.0)
        let c = CountingSemiring<Double>(0.5)
        let lhs: CountingSemiring<Double> = a.plus(b).times(c)
        let rhs: CountingSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: CountingSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-205 ⊗ is commutative (not a requirement) (CountingSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr205() {
        // a ⊗ b == b ⊗ a → both -3.375
        let a = CountingSemiring<Double>(1.5)
        let b = CountingSemiring<Double>(-2.25)
        let lhs: CountingSemiring<Double> = a.times(b)
        let rhs: CountingSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -3.375 && rhs.value == -3.375)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊗ b
        let rhsOperators: CountingSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-206 ⊗ is commutative (not a requirement) (CountingSemiring<Double>: a = 0.0, b = 1.0, c = 0.5)")
    func sr206() {
        // a ⊗ b == b ⊗ a → both 0.0
        let a = CountingSemiring<Double>(0.0)
        let b = CountingSemiring<Double>(1.0)
        let lhs: CountingSemiring<Double> = a.times(b)
        let rhs: CountingSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: CountingSemiring<Double> = a ⊗ b
        let rhsOperators: CountingSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-207 not idempotent (CountingSemiring<Double>: a = 1.5)")
    func sr207() {
        // a ⊕ a == a → false (a ⊕ a = 3.0)
        let a = CountingSemiring<Double>(1.5)
        let sum = a.plus(a)
        #expect(sum != a)
        #expect(sum.value == 3.0)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-361 ⊗ is associative (TropicalSemiring<Int8>: a = 100, b = Int8.max, c = -28)")
    func sr361() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int8.max
        let a = TropicalSemiring<Int8>(100)
        let b = TropicalSemiring<Int8>(Int8.max)
        let c = TropicalSemiring<Int8>(-28)
        let lhs: TropicalSemiring<Int8> = a.times(b).times(c)
        let rhs: TropicalSemiring<Int8> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int8.max && rhs.value == Int8.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int8> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int8> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-362 zero annihilates (TropicalSemiring<Int8>: a = 100, b = Int8.max, c = -28)")
    func sr362() {
        // .zero ⊗ a == a ⊗ .zero → both Int8.max
        let a = TropicalSemiring<Int8>(100)
        let lhs: TropicalSemiring<Int8> = TropicalSemiring<Int8>.zero.times(a)
        let rhs: TropicalSemiring<Int8> = a.times(TropicalSemiring<Int8>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int8.max && rhs.value == Int8.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int8> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Int8> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-363 ⊗ distributes over ⊕ from the left (TropicalSemiring<Int8>: a = 100, b = Int8.max, c = -28)")
    func sr363() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 72
        let a = TropicalSemiring<Int8>(100)
        let b = TropicalSemiring<Int8>(Int8.max)
        let c = TropicalSemiring<Int8>(-28)
        let lhs: TropicalSemiring<Int8> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Int8> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 72 && rhs.value == 72)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int8> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Int8> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-364 selective: a ⊕ b is the better by < (TropicalSemiring<Int8>: a = 100, b = Int8.max)")
    func sr364() {
        // a ⊕ b == (b < a ? b : a) → true (100)
        let a = TropicalSemiring<Int8>(100)
        let b = TropicalSemiring<Int8>(Int8.max)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 100)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-365 ⊗ is associative (TropicalSemiring<Int16>: a = Int16.min, b = 7, c = Int16.max)")
    func sr365() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int16.max
        let a = TropicalSemiring<Int16>(Int16.min)
        let b = TropicalSemiring<Int16>(7)
        let c = TropicalSemiring<Int16>(Int16.max)
        let lhs: TropicalSemiring<Int16> = a.times(b).times(c)
        let rhs: TropicalSemiring<Int16> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int16.max && rhs.value == Int16.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int16> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int16> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-366 zero annihilates (TropicalSemiring<Int16>: a = Int16.min, b = 7, c = Int16.max)")
    func sr366() {
        // .zero ⊗ a == a ⊗ .zero → both Int16.max
        let a = TropicalSemiring<Int16>(Int16.min)
        let lhs: TropicalSemiring<Int16> = TropicalSemiring<Int16>.zero.times(a)
        let rhs: TropicalSemiring<Int16> = a.times(TropicalSemiring<Int16>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int16.max && rhs.value == Int16.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int16> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Int16> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-367 ⊗ distributes over ⊕ from the left (TropicalSemiring<Int16>: a = Int16.min, b = 7, c = Int16.max)")
    func sr367() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both Int16.min
        let a = TropicalSemiring<Int16>(Int16.min)
        let b = TropicalSemiring<Int16>(7)
        let c = TropicalSemiring<Int16>(Int16.max)
        let lhs: TropicalSemiring<Int16> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Int16> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int16.min && rhs.value == Int16.min)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int16> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Int16> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-368 selective: a ⊕ b is the better by < (TropicalSemiring<Int16>: a = Int16.min, b = 7)")
    func sr368() {
        // a ⊕ b == (b < a ? b : a) → true (Int16.min)
        let a = TropicalSemiring<Int16>(Int16.min)
        let b = TropicalSemiring<Int16>(7)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == Int16.min)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-369 ⊗ is associative (TropicalSemiring<Int32>: a = 2000000000, b = -1, c = Int32.max)")
    func sr369() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int32.max
        let a = TropicalSemiring<Int32>(2000000000)
        let b = TropicalSemiring<Int32>(-1)
        let c = TropicalSemiring<Int32>(Int32.max)
        let lhs: TropicalSemiring<Int32> = a.times(b).times(c)
        let rhs: TropicalSemiring<Int32> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int32.max && rhs.value == Int32.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int32> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Int32> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-370 zero annihilates (TropicalSemiring<Int32>: a = 2000000000, b = -1, c = Int32.max)")
    func sr370() {
        // .zero ⊗ a == a ⊗ .zero → both Int32.max
        let a = TropicalSemiring<Int32>(2000000000)
        let lhs: TropicalSemiring<Int32> = TropicalSemiring<Int32>.zero.times(a)
        let rhs: TropicalSemiring<Int32> = a.times(TropicalSemiring<Int32>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int32.max && rhs.value == Int32.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int32> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Int32> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-371 ⊗ distributes over ⊕ from the left (TropicalSemiring<Int32>: a = 2000000000, b = -1, c = Int32.max)")
    func sr371() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 1999999999
        let a = TropicalSemiring<Int32>(2000000000)
        let b = TropicalSemiring<Int32>(-1)
        let c = TropicalSemiring<Int32>(Int32.max)
        let lhs: TropicalSemiring<Int32> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Int32> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1999999999 && rhs.value == 1999999999)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Int32> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Int32> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-372 selective: a ⊕ b is the better by < (TropicalSemiring<Int32>: a = 2000000000, b = -1)")
    func sr372() {
        // a ⊕ b == (b < a ? b : a) → true (-1)
        let a = TropicalSemiring<Int32>(2000000000)
        let b = TropicalSemiring<Int32>(-1)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == -1)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-373 ⊗ is associative (TropicalSemiring<UInt8>: a = 200, b = 55, c = UInt8.max)")
    func sr373() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both UInt8.max
        let a = TropicalSemiring<UInt8>(200)
        let b = TropicalSemiring<UInt8>(55)
        let c = TropicalSemiring<UInt8>(UInt8.max)
        let lhs: TropicalSemiring<UInt8> = a.times(b).times(c)
        let rhs: TropicalSemiring<UInt8> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == UInt8.max && rhs.value == UInt8.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt8> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<UInt8> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-374 zero annihilates (TropicalSemiring<UInt8>: a = 200, b = 55, c = UInt8.max)")
    func sr374() {
        // .zero ⊗ a == a ⊗ .zero → both UInt8.max
        let a = TropicalSemiring<UInt8>(200)
        let lhs: TropicalSemiring<UInt8> = TropicalSemiring<UInt8>.zero.times(a)
        let rhs: TropicalSemiring<UInt8> = a.times(TropicalSemiring<UInt8>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == UInt8.max && rhs.value == UInt8.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt8> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<UInt8> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-375 ⊗ distributes over ⊕ from the left (TropicalSemiring<UInt8>: a = 200, b = 55, c = UInt8.max)")
    func sr375() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both UInt8.max
        let a = TropicalSemiring<UInt8>(200)
        let b = TropicalSemiring<UInt8>(55)
        let c = TropicalSemiring<UInt8>(UInt8.max)
        let lhs: TropicalSemiring<UInt8> = a.times(b.plus(c))
        let rhs: TropicalSemiring<UInt8> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == UInt8.max && rhs.value == UInt8.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt8> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<UInt8> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-376 selective: a ⊕ b is the better by < (TropicalSemiring<UInt8>: a = 200, b = 55)")
    func sr376() {
        // a ⊕ b == (b < a ? b : a) → true (55)
        let a = TropicalSemiring<UInt8>(200)
        let b = TropicalSemiring<UInt8>(55)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 55)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-377 ⊗ is associative (TropicalSemiring<UInt16>: a = 1, b = 2, c = UInt16.max)")
    func sr377() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both UInt16.max
        let a = TropicalSemiring<UInt16>(1)
        let b = TropicalSemiring<UInt16>(2)
        let c = TropicalSemiring<UInt16>(UInt16.max)
        let lhs: TropicalSemiring<UInt16> = a.times(b).times(c)
        let rhs: TropicalSemiring<UInt16> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == UInt16.max && rhs.value == UInt16.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt16> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<UInt16> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-378 zero annihilates (TropicalSemiring<UInt16>: a = 1, b = 2, c = UInt16.max)")
    func sr378() {
        // .zero ⊗ a == a ⊗ .zero → both UInt16.max
        let a = TropicalSemiring<UInt16>(1)
        let lhs: TropicalSemiring<UInt16> = TropicalSemiring<UInt16>.zero.times(a)
        let rhs: TropicalSemiring<UInt16> = a.times(TropicalSemiring<UInt16>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == UInt16.max && rhs.value == UInt16.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt16> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<UInt16> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-379 ⊗ distributes over ⊕ from the left (TropicalSemiring<UInt16>: a = 1, b = 2, c = UInt16.max)")
    func sr379() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 3
        let a = TropicalSemiring<UInt16>(1)
        let b = TropicalSemiring<UInt16>(2)
        let c = TropicalSemiring<UInt16>(UInt16.max)
        let lhs: TropicalSemiring<UInt16> = a.times(b.plus(c))
        let rhs: TropicalSemiring<UInt16> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt16> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<UInt16> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-380 selective: a ⊕ b is the better by < (TropicalSemiring<UInt16>: a = 1, b = 2)")
    func sr380() {
        // a ⊕ b == (b < a ? b : a) → true (1)
        let a = TropicalSemiring<UInt16>(1)
        let b = TropicalSemiring<UInt16>(2)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 1)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-381 ⊗ is associative (TropicalSemiring<UInt32>: a = 4000000000, b = 294967295, c = 0)")
    func sr381() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both UInt32.max
        let a = TropicalSemiring<UInt32>(4000000000)
        let b = TropicalSemiring<UInt32>(294967295)
        let c = TropicalSemiring<UInt32>(0)
        let lhs: TropicalSemiring<UInt32> = a.times(b).times(c)
        let rhs: TropicalSemiring<UInt32> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == UInt32.max && rhs.value == UInt32.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt32> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<UInt32> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-382 zero annihilates (TropicalSemiring<UInt32>: a = 4000000000, b = 294967295, c = 0)")
    func sr382() {
        // .zero ⊗ a == a ⊗ .zero → both UInt32.max
        let a = TropicalSemiring<UInt32>(4000000000)
        let lhs: TropicalSemiring<UInt32> = TropicalSemiring<UInt32>.zero.times(a)
        let rhs: TropicalSemiring<UInt32> = a.times(TropicalSemiring<UInt32>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == UInt32.max && rhs.value == UInt32.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt32> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<UInt32> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-383 ⊗ distributes over ⊕ from the left (TropicalSemiring<UInt32>: a = 4000000000, b = 294967295, c = 0)")
    func sr383() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 4000000000
        let a = TropicalSemiring<UInt32>(4000000000)
        let b = TropicalSemiring<UInt32>(294967295)
        let c = TropicalSemiring<UInt32>(0)
        let lhs: TropicalSemiring<UInt32> = a.times(b.plus(c))
        let rhs: TropicalSemiring<UInt32> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 4000000000 && rhs.value == 4000000000)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt32> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<UInt32> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-384 selective: a ⊕ b is the better by < (TropicalSemiring<UInt32>: a = 4000000000, b = 294967295)")
    func sr384() {
        // a ⊕ b == (b < a ? b : a) → true (294967295)
        let a = TropicalSemiring<UInt32>(4000000000)
        let b = TropicalSemiring<UInt32>(294967295)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 294967295)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-385 ⊗ is associative (TropicalSemiring<UInt64>: a = UInt64.max - 1, b = 1, c = 0)")
    func sr385() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both UInt64.max
        let a = TropicalSemiring<UInt64>(UInt64.max - 1)
        let b = TropicalSemiring<UInt64>(1)
        let c = TropicalSemiring<UInt64>(0)
        let lhs: TropicalSemiring<UInt64> = a.times(b).times(c)
        let rhs: TropicalSemiring<UInt64> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == UInt64.max && rhs.value == UInt64.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt64> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<UInt64> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-386 zero annihilates (TropicalSemiring<UInt64>: a = UInt64.max - 1, b = 1, c = 0)")
    func sr386() {
        // .zero ⊗ a == a ⊗ .zero → both UInt64.max
        let a = TropicalSemiring<UInt64>(UInt64.max - 1)
        let lhs: TropicalSemiring<UInt64> = TropicalSemiring<UInt64>.zero.times(a)
        let rhs: TropicalSemiring<UInt64> = a.times(TropicalSemiring<UInt64>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == UInt64.max && rhs.value == UInt64.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt64> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<UInt64> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-387 ⊗ distributes over ⊕ from the left (TropicalSemiring<UInt64>: a = UInt64.max - 1, b = 1, c = 0)")
    func sr387() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 18446744073709551614
        let a = TropicalSemiring<UInt64>(UInt64.max - 1)
        let b = TropicalSemiring<UInt64>(1)
        let c = TropicalSemiring<UInt64>(0)
        let lhs: TropicalSemiring<UInt64> = a.times(b.plus(c))
        let rhs: TropicalSemiring<UInt64> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 18446744073709551614 && rhs.value == 18446744073709551614)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt64> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<UInt64> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-388 selective: a ⊕ b is the better by < (TropicalSemiring<UInt64>: a = UInt64.max - 1, b = 1)")
    func sr388() {
        // a ⊕ b == (b < a ? b : a) → true (1)
        let a = TropicalSemiring<UInt64>(UInt64.max - 1)
        let b = TropicalSemiring<UInt64>(1)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 1)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-389 ⊗ is associative (TropicalSemiring<UInt>: a = 3, b = UInt.max, c = 0)")
    func sr389() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both UInt.max
        let a = TropicalSemiring<UInt>(3)
        let b = TropicalSemiring<UInt>(UInt.max)
        let c = TropicalSemiring<UInt>(0)
        let lhs: TropicalSemiring<UInt> = a.times(b).times(c)
        let rhs: TropicalSemiring<UInt> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == UInt.max && rhs.value == UInt.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<UInt> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-390 zero annihilates (TropicalSemiring<UInt>: a = 3, b = UInt.max, c = 0)")
    func sr390() {
        // .zero ⊗ a == a ⊗ .zero → both UInt.max
        let a = TropicalSemiring<UInt>(3)
        let lhs: TropicalSemiring<UInt> = TropicalSemiring<UInt>.zero.times(a)
        let rhs: TropicalSemiring<UInt> = a.times(TropicalSemiring<UInt>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == UInt.max && rhs.value == UInt.max)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<UInt> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-391 ⊗ distributes over ⊕ from the left (TropicalSemiring<UInt>: a = 3, b = UInt.max, c = 0)")
    func sr391() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 3
        let a = TropicalSemiring<UInt>(3)
        let b = TropicalSemiring<UInt>(UInt.max)
        let c = TropicalSemiring<UInt>(0)
        let lhs: TropicalSemiring<UInt> = a.times(b.plus(c))
        let rhs: TropicalSemiring<UInt> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<UInt> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<UInt> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-392 selective: a ⊕ b is the better by < (TropicalSemiring<UInt>: a = 3, b = UInt.max)")
    func sr392() {
        // a ⊕ b == (b < a ? b : a) → true (3)
        let a = TropicalSemiring<UInt>(3)
        let b = TropicalSemiring<UInt>(UInt.max)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 3)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-393 ⊗ is associative (BottleneckSemiring<UInt>: a = 0, b = UInt.max, c = 7)")
    func sr393() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 0
        let a = BottleneckSemiring<UInt>(0)
        let b = BottleneckSemiring<UInt>(UInt.max)
        let c = BottleneckSemiring<UInt>(7)
        let lhs: BottleneckSemiring<UInt> = a.times(b).times(c)
        let rhs: BottleneckSemiring<UInt> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<UInt> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<UInt> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-394 zero annihilates (BottleneckSemiring<UInt>: a = 0, b = UInt.max, c = 7)")
    func sr394() {
        // .zero ⊗ a == a ⊗ .zero → both 0
        let a = BottleneckSemiring<UInt>(0)
        let lhs: BottleneckSemiring<UInt> = BottleneckSemiring<UInt>.zero.times(a)
        let rhs: BottleneckSemiring<UInt> = a.times(BottleneckSemiring<UInt>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<UInt> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<UInt> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-395 ⊗ distributes over ⊕ from the left (BottleneckSemiring<UInt>: a = 0, b = UInt.max, c = 7)")
    func sr395() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 0
        let a = BottleneckSemiring<UInt>(0)
        let b = BottleneckSemiring<UInt>(UInt.max)
        let c = BottleneckSemiring<UInt>(7)
        let lhs: BottleneckSemiring<UInt> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<UInt> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<UInt> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<UInt> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-396 selective: a ⊕ b is the better by < (BottleneckSemiring<UInt>: a = 0, b = UInt.max)")
    func sr396() {
        // a ⊕ b == (b < a ? b : a) → true (UInt.max)
        let a = BottleneckSemiring<UInt>(0)
        let b = BottleneckSemiring<UInt>(UInt.max)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == UInt.max)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-397 ⊗ is associative (BottleneckSemiring<UInt8>: a = 5, b = 0, c = UInt8.max)")
    func sr397() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 0
        let a = BottleneckSemiring<UInt8>(5)
        let b = BottleneckSemiring<UInt8>(0)
        let c = BottleneckSemiring<UInt8>(UInt8.max)
        let lhs: BottleneckSemiring<UInt8> = a.times(b).times(c)
        let rhs: BottleneckSemiring<UInt8> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<UInt8> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<UInt8> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-398 zero annihilates (BottleneckSemiring<UInt8>: a = 5, b = 0, c = UInt8.max)")
    func sr398() {
        // .zero ⊗ a == a ⊗ .zero → both 0
        let a = BottleneckSemiring<UInt8>(5)
        let lhs: BottleneckSemiring<UInt8> = BottleneckSemiring<UInt8>.zero.times(a)
        let rhs: BottleneckSemiring<UInt8> = a.times(BottleneckSemiring<UInt8>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0 && rhs.value == 0)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<UInt8> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<UInt8> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-399 ⊗ distributes over ⊕ from the left (BottleneckSemiring<UInt8>: a = 5, b = 0, c = UInt8.max)")
    func sr399() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 5
        let a = BottleneckSemiring<UInt8>(5)
        let b = BottleneckSemiring<UInt8>(0)
        let c = BottleneckSemiring<UInt8>(UInt8.max)
        let lhs: BottleneckSemiring<UInt8> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<UInt8> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<UInt8> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<UInt8> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-400 selective: a ⊕ b is the better by < (BottleneckSemiring<UInt8>: a = 5, b = 0)")
    func sr400() {
        // a ⊕ b == (b < a ? b : a) → true (5)
        let a = BottleneckSemiring<UInt8>(5)
        let b = BottleneckSemiring<UInt8>(0)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-401 ⊗ is associative (TropicalSemiring<Float>: a = 1.7014118346046923e+38, b = 1.7014118346046923e+38, c = -0.5)")
    func sr401() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both .infinity
        let a = TropicalSemiring<Float>(1.7014118346046923e+38)
        let b = TropicalSemiring<Float>(1.7014118346046923e+38)
        let c = TropicalSemiring<Float>(-0.5)
        let lhs: TropicalSemiring<Float> = a.times(b).times(c)
        let rhs: TropicalSemiring<Float> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Float.infinity && rhs.value == Float.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Float> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Float> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-402 zero annihilates (TropicalSemiring<Float>: a = 1.7014118346046923e+38, b = 1.7014118346046923e+38, c = -0.5)")
    func sr402() {
        // .zero ⊗ a == a ⊗ .zero → both .infinity
        let a = TropicalSemiring<Float>(1.7014118346046923e+38)
        let lhs: TropicalSemiring<Float> = TropicalSemiring<Float>.zero.times(a)
        let rhs: TropicalSemiring<Float> = a.times(TropicalSemiring<Float>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Float.infinity && rhs.value == Float.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Float> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Float> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-403 ⊗ distributes over ⊕ from the left (TropicalSemiring<Float>: a = 1.7014118346046923e+38, b = 1.7014118346046923e+38, c = -0.5)")
    func sr403() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 1.7014118346046923e+38
        let a = TropicalSemiring<Float>(1.7014118346046923e+38)
        let b = TropicalSemiring<Float>(1.7014118346046923e+38)
        let c = TropicalSemiring<Float>(-0.5)
        let lhs: TropicalSemiring<Float> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Float> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1.7014118346046923e+38 && rhs.value == 1.7014118346046923e+38)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Float> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Float> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-404 selective: a ⊕ b is the better by < (TropicalSemiring<Float>: a = 1.7014118346046923e+38, b = 1.7014118346046923e+38)")
    func sr404() {
        // a ⊕ b == (b < a ? b : a) → true (1.7014118346046923e+38)
        let a = TropicalSemiring<Float>(1.7014118346046923e+38)
        let b = TropicalSemiring<Float>(1.7014118346046923e+38)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 1.7014118346046923e+38)
        #expect((a ⊕ b) == sum)
    }

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-405 ⊗ is associative (TropicalSemiring<Float16>: a = 32768.0, b = 32768.0, c = .infinity)")
    func sr405() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both .infinity
        let a = TropicalSemiring<Float16>(32768.0)
        let b = TropicalSemiring<Float16>(32768.0)
        let c = TropicalSemiring<Float16>(Float16.infinity)
        let lhs: TropicalSemiring<Float16> = a.times(b).times(c)
        let rhs: TropicalSemiring<Float16> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Float16.infinity && rhs.value == Float16.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Float16> = (a ⊗ b) ⊗ c
        let rhsOperators: TropicalSemiring<Float16> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-406 zero annihilates (TropicalSemiring<Float16>: a = 32768.0, b = 32768.0, c = .infinity)")
    func sr406() {
        // .zero ⊗ a == a ⊗ .zero → both .infinity
        let a = TropicalSemiring<Float16>(32768.0)
        let lhs: TropicalSemiring<Float16> = TropicalSemiring<Float16>.zero.times(a)
        let rhs: TropicalSemiring<Float16> = a.times(TropicalSemiring<Float16>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Float16.infinity && rhs.value == Float16.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Float16> = .zero ⊗ a
        let rhsOperators: TropicalSemiring<Float16> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-407 ⊗ distributes over ⊕ from the left (TropicalSemiring<Float16>: a = 32768.0, b = 32768.0, c = .infinity)")
    func sr407() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both .infinity
        let a = TropicalSemiring<Float16>(32768.0)
        let b = TropicalSemiring<Float16>(32768.0)
        let c = TropicalSemiring<Float16>(Float16.infinity)
        let lhs: TropicalSemiring<Float16> = a.times(b.plus(c))
        let rhs: TropicalSemiring<Float16> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Float16.infinity && rhs.value == Float16.infinity)
        // The operators call the methods.
        let lhsOperators: TropicalSemiring<Float16> = a ⊗ (b ⊕ c)
        let rhsOperators: TropicalSemiring<Float16> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-408 selective: a ⊕ b is the better by < (TropicalSemiring<Float16>: a = 32768.0, b = 32768.0)")
    func sr408() {
        // a ⊕ b == (b < a ? b : a) → true (32768.0)
        let a = TropicalSemiring<Float16>(32768.0)
        let b = TropicalSemiring<Float16>(32768.0)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 32768.0)
        #expect((a ⊕ b) == sum)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-409 ⊗ is associative (BottleneckSemiring<Float16>: a = -.infinity, b = 65504.0, c = 0.5)")
    func sr409() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -.infinity
        let a = BottleneckSemiring<Float16>(-Float16.infinity)
        let b = BottleneckSemiring<Float16>(65504.0)
        let c = BottleneckSemiring<Float16>(0.5)
        let lhs: BottleneckSemiring<Float16> = a.times(b).times(c)
        let rhs: BottleneckSemiring<Float16> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -Float16.infinity && rhs.value == -Float16.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Float16> = (a ⊗ b) ⊗ c
        let rhsOperators: BottleneckSemiring<Float16> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-410 zero annihilates (BottleneckSemiring<Float16>: a = -.infinity, b = 65504.0, c = 0.5)")
    func sr410() {
        // .zero ⊗ a == a ⊗ .zero → both -.infinity
        let a = BottleneckSemiring<Float16>(-Float16.infinity)
        let lhs: BottleneckSemiring<Float16> = BottleneckSemiring<Float16>.zero.times(a)
        let rhs: BottleneckSemiring<Float16> = a.times(BottleneckSemiring<Float16>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == -Float16.infinity && rhs.value == -Float16.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Float16> = .zero ⊗ a
        let rhsOperators: BottleneckSemiring<Float16> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-411 ⊗ distributes over ⊕ from the left (BottleneckSemiring<Float16>: a = -.infinity, b = 65504.0, c = 0.5)")
    func sr411() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both -.infinity
        let a = BottleneckSemiring<Float16>(-Float16.infinity)
        let b = BottleneckSemiring<Float16>(65504.0)
        let c = BottleneckSemiring<Float16>(0.5)
        let lhs: BottleneckSemiring<Float16> = a.times(b.plus(c))
        let rhs: BottleneckSemiring<Float16> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -Float16.infinity && rhs.value == -Float16.infinity)
        // The operators call the methods.
        let lhsOperators: BottleneckSemiring<Float16> = a ⊗ (b ⊕ c)
        let rhsOperators: BottleneckSemiring<Float16> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }
    #endif

    #if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))
    @Test("SR-412 selective: a ⊕ b is the better by < (BottleneckSemiring<Float16>: a = -.infinity, b = 65504.0)")
    func sr412() {
        // a ⊕ b == (b < a ? b : a) → true (65504.0)
        let a = BottleneckSemiring<Float16>(-Float16.infinity)
        let b = BottleneckSemiring<Float16>(65504.0)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 65504.0)
        #expect((a ⊕ b) == sum)
    }
    #endif

    @Test("SR-460 ⊕ is associative (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr460() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 7
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let c = MaxPlusSemiring<Int>(7)
        let lhs: MaxPlusSemiring<Int> = a.plus(b).plus(c)
        let rhs: MaxPlusSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 7 && rhs.value == 7)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: MaxPlusSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-461 ⊕ is associative (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr461() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 5
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let c = MaxPlusSemiring<Int>(0)
        let lhs: MaxPlusSemiring<Int> = a.plus(b).plus(c)
        let rhs: MaxPlusSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: MaxPlusSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-462 ⊕ is associative (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr462() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both -4
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let c = MaxPlusSemiring<Int>(Int.min)
        let lhs: MaxPlusSemiring<Int> = a.plus(b).plus(c)
        let rhs: MaxPlusSemiring<Int> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊕ b) ⊕ c
        let rhsOperators: MaxPlusSemiring<Int> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-463 ⊕ is commutative (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr463() {
        // a ⊕ b == b ⊕ a → both 3
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let lhs: MaxPlusSemiring<Int> = a.plus(b)
        let rhs: MaxPlusSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊕ b
        let rhsOperators: MaxPlusSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-464 ⊕ is commutative (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr464() {
        // a ⊕ b == b ⊕ a → both 5
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let lhs: MaxPlusSemiring<Int> = a.plus(b)
        let rhs: MaxPlusSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊕ b
        let rhsOperators: MaxPlusSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-465 ⊕ is commutative (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr465() {
        // a ⊕ b == b ⊕ a → both -4
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let lhs: MaxPlusSemiring<Int> = a.plus(b)
        let rhs: MaxPlusSemiring<Int> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊕ b
        let rhsOperators: MaxPlusSemiring<Int> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-466 zero is ⊕'s identity (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr466() {
        // a ⊕ .zero == a → both 3
        let a = MaxPlusSemiring<Int>(3)
        let lhs: MaxPlusSemiring<Int> = a.plus(MaxPlusSemiring<Int>.zero)
        let rhs: MaxPlusSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊕ .zero
        let rhsOperators: MaxPlusSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-467 zero is ⊕'s identity (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr467() {
        // a ⊕ .zero == a → both 5
        let a = MaxPlusSemiring<Int>(5)
        let lhs: MaxPlusSemiring<Int> = a.plus(MaxPlusSemiring<Int>.zero)
        let rhs: MaxPlusSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊕ .zero
        let rhsOperators: MaxPlusSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-468 zero is ⊕'s identity (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr468() {
        // a ⊕ .zero == a → both -4
        let a = MaxPlusSemiring<Int>(-4)
        let lhs: MaxPlusSemiring<Int> = a.plus(MaxPlusSemiring<Int>.zero)
        let rhs: MaxPlusSemiring<Int> = a
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊕ .zero
        let rhsOperators: MaxPlusSemiring<Int> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-469 ⊗ is associative (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr469() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 8
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let c = MaxPlusSemiring<Int>(7)
        let lhs: MaxPlusSemiring<Int> = a.times(b).times(c)
        let rhs: MaxPlusSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 8 && rhs.value == 8)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-470 ⊗ is associative (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr470() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int.min
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let c = MaxPlusSemiring<Int>(0)
        let lhs: MaxPlusSemiring<Int> = a.times(b).times(c)
        let rhs: MaxPlusSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-471 ⊗ is associative (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr471() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both Int.min
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let c = MaxPlusSemiring<Int>(Int.min)
        let lhs: MaxPlusSemiring<Int> = a.times(b).times(c)
        let rhs: MaxPlusSemiring<Int> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊗ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-472 one is ⊗'s identity (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr472() {
        // .one ⊗ a == a ⊗ .one → both 3
        let a = MaxPlusSemiring<Int>(3)
        let lhs: MaxPlusSemiring<Int> = MaxPlusSemiring<Int>.one.times(a)
        let rhs: MaxPlusSemiring<Int> = a.times(MaxPlusSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 3 && rhs.value == 3)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = .one ⊗ a
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-473 one is ⊗'s identity (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr473() {
        // .one ⊗ a == a ⊗ .one → both 5
        let a = MaxPlusSemiring<Int>(5)
        let lhs: MaxPlusSemiring<Int> = MaxPlusSemiring<Int>.one.times(a)
        let rhs: MaxPlusSemiring<Int> = a.times(MaxPlusSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = .one ⊗ a
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-474 one is ⊗'s identity (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr474() {
        // .one ⊗ a == a ⊗ .one → both -4
        let a = MaxPlusSemiring<Int>(-4)
        let lhs: MaxPlusSemiring<Int> = MaxPlusSemiring<Int>.one.times(a)
        let rhs: MaxPlusSemiring<Int> = a.times(MaxPlusSemiring<Int>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == -4 && rhs.value == -4)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = .one ⊗ a
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-475 zero annihilates (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr475() {
        // .zero ⊗ a == a ⊗ .zero → both Int.min
        let a = MaxPlusSemiring<Int>(3)
        let lhs: MaxPlusSemiring<Int> = MaxPlusSemiring<Int>.zero.times(a)
        let rhs: MaxPlusSemiring<Int> = a.times(MaxPlusSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = .zero ⊗ a
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-476 zero annihilates (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr476() {
        // .zero ⊗ a == a ⊗ .zero → both Int.min
        let a = MaxPlusSemiring<Int>(5)
        let lhs: MaxPlusSemiring<Int> = MaxPlusSemiring<Int>.zero.times(a)
        let rhs: MaxPlusSemiring<Int> = a.times(MaxPlusSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = .zero ⊗ a
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-477 zero annihilates (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr477() {
        // .zero ⊗ a == a ⊗ .zero → both Int.min
        let a = MaxPlusSemiring<Int>(-4)
        let lhs: MaxPlusSemiring<Int> = MaxPlusSemiring<Int>.zero.times(a)
        let rhs: MaxPlusSemiring<Int> = a.times(MaxPlusSemiring<Int>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = .zero ⊗ a
        let rhsOperators: MaxPlusSemiring<Int> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-478 ⊗ distributes over ⊕ from the left (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr478() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 10
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let c = MaxPlusSemiring<Int>(7)
        let lhs: MaxPlusSemiring<Int> = a.times(b.plus(c))
        let rhs: MaxPlusSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 10 && rhs.value == 10)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: MaxPlusSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-479 ⊗ distributes over ⊕ from the left (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr479() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 5
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let c = MaxPlusSemiring<Int>(0)
        let lhs: MaxPlusSemiring<Int> = a.times(b.plus(c))
        let rhs: MaxPlusSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: MaxPlusSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-480 ⊗ distributes over ⊕ from the left (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr480() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both -8
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let c = MaxPlusSemiring<Int>(Int.min)
        let lhs: MaxPlusSemiring<Int> = a.times(b.plus(c))
        let rhs: MaxPlusSemiring<Int> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -8 && rhs.value == -8)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊗ (b ⊕ c)
        let rhsOperators: MaxPlusSemiring<Int> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-481 ⊗ distributes over ⊕ from the right (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr481() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 10
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let c = MaxPlusSemiring<Int>(7)
        let lhs: MaxPlusSemiring<Int> = a.plus(b).times(c)
        let rhs: MaxPlusSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 10 && rhs.value == 10)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-482 ⊗ distributes over ⊕ from the right (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr482() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 5
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let c = MaxPlusSemiring<Int>(0)
        let lhs: MaxPlusSemiring<Int> = a.plus(b).times(c)
        let rhs: MaxPlusSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5 && rhs.value == 5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-483 ⊗ distributes over ⊕ from the right (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr483() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both Int.min
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let c = MaxPlusSemiring<Int>(Int.min)
        let lhs: MaxPlusSemiring<Int> = a.plus(b).times(c)
        let rhs: MaxPlusSemiring<Int> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = (a ⊕ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Int> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-484 ⊗ is commutative (not a requirement) (MaxPlusSemiring<Int>: a = 3, b = -2, c = 7)")
    func sr484() {
        // a ⊗ b == b ⊗ a → both 1
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let lhs: MaxPlusSemiring<Int> = a.times(b)
        let rhs: MaxPlusSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1 && rhs.value == 1)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊗ b
        let rhsOperators: MaxPlusSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-485 ⊗ is commutative (not a requirement) (MaxPlusSemiring<Int>: a = 5, b = Int.min, c = 0)")
    func sr485() {
        // a ⊗ b == b ⊗ a → both Int.min
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let lhs: MaxPlusSemiring<Int> = a.times(b)
        let rhs: MaxPlusSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == Int.min && rhs.value == Int.min)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊗ b
        let rhsOperators: MaxPlusSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-486 ⊗ is commutative (not a requirement) (MaxPlusSemiring<Int>: a = -4, b = -4, c = Int.min)")
    func sr486() {
        // a ⊗ b == b ⊗ a → both -8
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let lhs: MaxPlusSemiring<Int> = a.times(b)
        let rhs: MaxPlusSemiring<Int> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -8 && rhs.value == -8)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Int> = a ⊗ b
        let rhsOperators: MaxPlusSemiring<Int> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-487 selective: a ⊕ b is the better by < (MaxPlusSemiring<Int>: a = 3, b = -2)")
    func sr487() {
        // a ⊕ b == (b < a ? b : a) → true (3)
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 3)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-488 idempotent (MaxPlusSemiring<Int>: a = 3)")
    func sr488() {
        // a ⊕ a == a → true (a ⊕ a = 3)
        let a = MaxPlusSemiring<Int>(3)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 3)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-489 selective: a ⊕ b is the better by < (MaxPlusSemiring<Int>: a = 5, b = Int.min)")
    func sr489() {
        // a ⊕ b == (b < a ? b : a) → true (5)
        let a = MaxPlusSemiring<Int>(5)
        let b = MaxPlusSemiring<Int>(Int.min)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-490 idempotent (MaxPlusSemiring<Int>: a = 5)")
    func sr490() {
        // a ⊕ a == a → true (a ⊕ a = 5)
        let a = MaxPlusSemiring<Int>(5)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 5)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-491 selective: a ⊕ b is the better by < (MaxPlusSemiring<Int>: a = -4, b = -4)")
    func sr491() {
        // a ⊕ b == (b < a ? b : a) → true (-4)
        let a = MaxPlusSemiring<Int>(-4)
        let b = MaxPlusSemiring<Int>(-4)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == -4)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-492 idempotent (MaxPlusSemiring<Int>: a = -4)")
    func sr492() {
        // a ⊕ a == a → true (a ⊕ a = -4)
        let a = MaxPlusSemiring<Int>(-4)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == -4)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-493 the natural order: < is ‘better’ (MaxPlusSemiring<Int>: a = 3, b = -2)")
    func sr493() {
        // a < b → true
        let a = MaxPlusSemiring<Int>(3)
        let b = MaxPlusSemiring<Int>(-2)
        #expect((a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect(!(b < a) && a != b)
    }

    @Test("SR-494 zero is the greatest (worst) element (MaxPlusSemiring<Int>: a = 3)")
    func sr494() {
        // a < .zero || a == .zero → true
        let a = MaxPlusSemiring<Int>(3)
        #expect(a < .zero || a == .zero)
        #expect(!(MaxPlusSemiring<Int>.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-496 ⊕ is associative (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr496() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 4.0
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let c = MaxPlusSemiring<Double>(4.0)
        let lhs: MaxPlusSemiring<Double> = a.plus(b).plus(c)
        let rhs: MaxPlusSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 4.0 && rhs.value == 4.0)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: MaxPlusSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-497 ⊕ is associative (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr497() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 0.5
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let c = MaxPlusSemiring<Double>(-3.0)
        let lhs: MaxPlusSemiring<Double> = a.plus(b).plus(c)
        let rhs: MaxPlusSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: MaxPlusSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-498 ⊕ is commutative (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr498() {
        // a ⊕ b == b ⊕ a → both 1.5
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let lhs: MaxPlusSemiring<Double> = a.plus(b)
        let rhs: MaxPlusSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊕ b
        let rhsOperators: MaxPlusSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-499 ⊕ is commutative (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr499() {
        // a ⊕ b == b ⊕ a → both 0.5
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let lhs: MaxPlusSemiring<Double> = a.plus(b)
        let rhs: MaxPlusSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊕ b
        let rhsOperators: MaxPlusSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-500 zero is ⊕'s identity (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr500() {
        // a ⊕ .zero == a → both 1.5
        let a = MaxPlusSemiring<Double>(1.5)
        let lhs: MaxPlusSemiring<Double> = a.plus(MaxPlusSemiring<Double>.zero)
        let rhs: MaxPlusSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊕ .zero
        let rhsOperators: MaxPlusSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-501 zero is ⊕'s identity (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr501() {
        // a ⊕ .zero == a → both -.infinity
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let lhs: MaxPlusSemiring<Double> = a.plus(MaxPlusSemiring<Double>.zero)
        let rhs: MaxPlusSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊕ .zero
        let rhsOperators: MaxPlusSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-502 ⊗ is associative (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr502() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 3.25
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let c = MaxPlusSemiring<Double>(4.0)
        let lhs: MaxPlusSemiring<Double> = a.times(b).times(c)
        let rhs: MaxPlusSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 3.25 && rhs.value == 3.25)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-503 ⊗ is associative (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr503() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both -.infinity
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let c = MaxPlusSemiring<Double>(-3.0)
        let lhs: MaxPlusSemiring<Double> = a.times(b).times(c)
        let rhs: MaxPlusSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-504 one is ⊗'s identity (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr504() {
        // .one ⊗ a == a ⊗ .one → both 1.5
        let a = MaxPlusSemiring<Double>(1.5)
        let lhs: MaxPlusSemiring<Double> = MaxPlusSemiring<Double>.one.times(a)
        let rhs: MaxPlusSemiring<Double> = a.times(MaxPlusSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 1.5 && rhs.value == 1.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = .one ⊗ a
        let rhsOperators: MaxPlusSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-505 one is ⊗'s identity (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr505() {
        // .one ⊗ a == a ⊗ .one → both -.infinity
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let lhs: MaxPlusSemiring<Double> = MaxPlusSemiring<Double>.one.times(a)
        let rhs: MaxPlusSemiring<Double> = a.times(MaxPlusSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = .one ⊗ a
        let rhsOperators: MaxPlusSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-506 zero annihilates (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr506() {
        // .zero ⊗ a == a ⊗ .zero → both -.infinity
        let a = MaxPlusSemiring<Double>(1.5)
        let lhs: MaxPlusSemiring<Double> = MaxPlusSemiring<Double>.zero.times(a)
        let rhs: MaxPlusSemiring<Double> = a.times(MaxPlusSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = .zero ⊗ a
        let rhsOperators: MaxPlusSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-507 zero annihilates (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr507() {
        // .zero ⊗ a == a ⊗ .zero → both -.infinity
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let lhs: MaxPlusSemiring<Double> = MaxPlusSemiring<Double>.zero.times(a)
        let rhs: MaxPlusSemiring<Double> = a.times(MaxPlusSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = .zero ⊗ a
        let rhsOperators: MaxPlusSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-508 ⊗ distributes over ⊕ from the left (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr508() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 5.5
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let c = MaxPlusSemiring<Double>(4.0)
        let lhs: MaxPlusSemiring<Double> = a.times(b.plus(c))
        let rhs: MaxPlusSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5.5 && rhs.value == 5.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: MaxPlusSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-509 ⊗ distributes over ⊕ from the left (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr509() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both -.infinity
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let c = MaxPlusSemiring<Double>(-3.0)
        let lhs: MaxPlusSemiring<Double> = a.times(b.plus(c))
        let rhs: MaxPlusSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: MaxPlusSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-510 ⊗ distributes over ⊕ from the right (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr510() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 5.5
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let c = MaxPlusSemiring<Double>(4.0)
        let lhs: MaxPlusSemiring<Double> = a.plus(b).times(c)
        let rhs: MaxPlusSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 5.5 && rhs.value == 5.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-511 ⊗ distributes over ⊕ from the right (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr511() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both -2.5
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let c = MaxPlusSemiring<Double>(-3.0)
        let lhs: MaxPlusSemiring<Double> = a.plus(b).times(c)
        let rhs: MaxPlusSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == -2.5 && rhs.value == -2.5)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: MaxPlusSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-512 ⊗ is commutative (not a requirement) (MaxPlusSemiring<Double>: a = 1.5, b = -2.25, c = 4.0)")
    func sr512() {
        // a ⊗ b == b ⊗ a → both -0.75
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let lhs: MaxPlusSemiring<Double> = a.times(b)
        let rhs: MaxPlusSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -0.75 && rhs.value == -0.75)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊗ b
        let rhsOperators: MaxPlusSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-513 ⊗ is commutative (not a requirement) (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5, c = -3.0)")
    func sr513() {
        // a ⊗ b == b ⊗ a → both -.infinity
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let lhs: MaxPlusSemiring<Double> = a.times(b)
        let rhs: MaxPlusSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == -Double.infinity && rhs.value == -Double.infinity)
        // The operators call the methods.
        let lhsOperators: MaxPlusSemiring<Double> = a ⊗ b
        let rhsOperators: MaxPlusSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-514 selective: a ⊕ b is the better by < (MaxPlusSemiring<Double>: a = 1.5, b = -2.25)")
    func sr514() {
        // a ⊕ b == (b < a ? b : a) → true (1.5)
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 1.5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-515 idempotent (MaxPlusSemiring<Double>: a = 1.5)")
    func sr515() {
        // a ⊕ a == a → true (a ⊕ a = 1.5)
        let a = MaxPlusSemiring<Double>(1.5)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 1.5)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-516 selective: a ⊕ b is the better by < (MaxPlusSemiring<Double>: a = -.infinity, b = 0.5)")
    func sr516() {
        // a ⊕ b == (b < a ? b : a) → true (0.5)
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let b = MaxPlusSemiring<Double>(0.5)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 0.5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-517 idempotent (MaxPlusSemiring<Double>: a = -.infinity)")
    func sr517() {
        // a ⊕ a == a → true (a ⊕ a = -.infinity)
        let a = MaxPlusSemiring<Double>(-Double.infinity)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == -Double.infinity)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-518 the natural order: < is ‘better’ (MaxPlusSemiring<Double>: a = 1.5, b = -2.25)")
    func sr518() {
        // a < b → true
        let a = MaxPlusSemiring<Double>(1.5)
        let b = MaxPlusSemiring<Double>(-2.25)
        #expect((a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect(!(b < a) && a != b)
    }

    @Test("SR-519 zero is the greatest (worst) element (MaxPlusSemiring<Double>: a = 1.5)")
    func sr519() {
        // a < .zero || a == .zero → true
        let a = MaxPlusSemiring<Double>(1.5)
        #expect(a < .zero || a == .zero)
        #expect(!(MaxPlusSemiring<Double>.zero < a))
        #expect(a.plus(.zero) == a)
    }

    @Test("SR-521 ⊕ is associative (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr521() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 1.0
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let c = ViterbiSemiring<Double>(1.0)
        let lhs: ViterbiSemiring<Double> = a.plus(b).plus(c)
        let rhs: ViterbiSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 1.0 && rhs.value == 1.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: ViterbiSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-522 ⊕ is associative (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr522() {
        // (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c) → both 0.75
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let c = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = a.plus(b).plus(c)
        let rhs: ViterbiSemiring<Double> = a.plus(b.plus(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.75 && rhs.value == 0.75)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = (a ⊕ b) ⊕ c
        let rhsOperators: ViterbiSemiring<Double> = a ⊕ (b ⊕ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-523 ⊕ is commutative (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr523() {
        // a ⊕ b == b ⊕ a → both 0.5
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let lhs: ViterbiSemiring<Double> = a.plus(b)
        let rhs: ViterbiSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊕ b
        let rhsOperators: ViterbiSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-524 ⊕ is commutative (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr524() {
        // a ⊕ b == b ⊕ a → both 0.75
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let lhs: ViterbiSemiring<Double> = a.plus(b)
        let rhs: ViterbiSemiring<Double> = b.plus(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.75 && rhs.value == 0.75)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊕ b
        let rhsOperators: ViterbiSemiring<Double> = b ⊕ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-525 zero is ⊕'s identity (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr525() {
        // a ⊕ .zero == a → both 0.5
        let a = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = a.plus(ViterbiSemiring<Double>.zero)
        let rhs: ViterbiSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊕ .zero
        let rhsOperators: ViterbiSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-526 zero is ⊕'s identity (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr526() {
        // a ⊕ .zero == a → both 0.0
        let a = ViterbiSemiring<Double>(0.0)
        let lhs: ViterbiSemiring<Double> = a.plus(ViterbiSemiring<Double>.zero)
        let rhs: ViterbiSemiring<Double> = a
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊕ .zero
        let rhsOperators: ViterbiSemiring<Double> = a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-527 ⊗ is associative (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr527() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 0.125
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let c = ViterbiSemiring<Double>(1.0)
        let lhs: ViterbiSemiring<Double> = a.times(b).times(c)
        let rhs: ViterbiSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.125 && rhs.value == 0.125)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: ViterbiSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-528 ⊗ is associative (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr528() {
        // (a ⊗ b) ⊗ c == a ⊗ (b ⊗ c) → both 0.0
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let c = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = a.times(b).times(c)
        let rhs: ViterbiSemiring<Double> = a.times(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = (a ⊗ b) ⊗ c
        let rhsOperators: ViterbiSemiring<Double> = a ⊗ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-529 one is ⊗'s identity (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr529() {
        // .one ⊗ a == a ⊗ .one → both 0.5
        let a = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = ViterbiSemiring<Double>.one.times(a)
        let rhs: ViterbiSemiring<Double> = a.times(ViterbiSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = .one ⊗ a
        let rhsOperators: ViterbiSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-530 one is ⊗'s identity (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr530() {
        // .one ⊗ a == a ⊗ .one → both 0.0
        let a = ViterbiSemiring<Double>(0.0)
        let lhs: ViterbiSemiring<Double> = ViterbiSemiring<Double>.one.times(a)
        let rhs: ViterbiSemiring<Double> = a.times(ViterbiSemiring<Double>.one)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = .one ⊗ a
        let rhsOperators: ViterbiSemiring<Double> = a ⊗ .one
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-531 zero annihilates (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr531() {
        // .zero ⊗ a == a ⊗ .zero → both 0.0
        let a = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = ViterbiSemiring<Double>.zero.times(a)
        let rhs: ViterbiSemiring<Double> = a.times(ViterbiSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = .zero ⊗ a
        let rhsOperators: ViterbiSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-532 zero annihilates (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr532() {
        // .zero ⊗ a == a ⊗ .zero → both 0.0
        let a = ViterbiSemiring<Double>(0.0)
        let lhs: ViterbiSemiring<Double> = ViterbiSemiring<Double>.zero.times(a)
        let rhs: ViterbiSemiring<Double> = a.times(ViterbiSemiring<Double>.zero)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = .zero ⊗ a
        let rhsOperators: ViterbiSemiring<Double> = a ⊗ .zero
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-533 ⊗ distributes over ⊕ from the left (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr533() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 0.5
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let c = ViterbiSemiring<Double>(1.0)
        let lhs: ViterbiSemiring<Double> = a.times(b.plus(c))
        let rhs: ViterbiSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: ViterbiSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-534 ⊗ distributes over ⊕ from the left (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr534() {
        // a ⊗ (b ⊕ c) == (a ⊗ b) ⊕ (a ⊗ c) → both 0.0
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let c = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = a.times(b.plus(c))
        let rhs: ViterbiSemiring<Double> = a.times(b).plus(a.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊗ (b ⊕ c)
        let rhsOperators: ViterbiSemiring<Double> = (a ⊗ b) ⊕ (a ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-535 ⊗ distributes over ⊕ from the right (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr535() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 0.5
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let c = ViterbiSemiring<Double>(1.0)
        let lhs: ViterbiSemiring<Double> = a.plus(b).times(c)
        let rhs: ViterbiSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.5 && rhs.value == 0.5)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: ViterbiSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-536 ⊗ distributes over ⊕ from the right (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr536() {
        // (a ⊕ b) ⊗ c == (a ⊗ c) ⊕ (b ⊗ c) → both 0.375
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let c = ViterbiSemiring<Double>(0.5)
        let lhs: ViterbiSemiring<Double> = a.plus(b).times(c)
        let rhs: ViterbiSemiring<Double> = a.times(c).plus(b.times(c))
        #expect(lhs == rhs)
        #expect(lhs.value == 0.375 && rhs.value == 0.375)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = (a ⊕ b) ⊗ c
        let rhsOperators: ViterbiSemiring<Double> = (a ⊗ c) ⊕ (b ⊗ c)
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-537 ⊗ is commutative (not a requirement) (ViterbiSemiring<Double>: a = 0.5, b = 0.25, c = 1.0)")
    func sr537() {
        // a ⊗ b == b ⊗ a → both 0.125
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let lhs: ViterbiSemiring<Double> = a.times(b)
        let rhs: ViterbiSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.125 && rhs.value == 0.125)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊗ b
        let rhsOperators: ViterbiSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-538 ⊗ is commutative (not a requirement) (ViterbiSemiring<Double>: a = 0.0, b = 0.75, c = 0.5)")
    func sr538() {
        // a ⊗ b == b ⊗ a → both 0.0
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let lhs: ViterbiSemiring<Double> = a.times(b)
        let rhs: ViterbiSemiring<Double> = b.times(a)
        #expect(lhs == rhs)
        #expect(lhs.value == 0.0 && rhs.value == 0.0)
        // The operators call the methods.
        let lhsOperators: ViterbiSemiring<Double> = a ⊗ b
        let rhsOperators: ViterbiSemiring<Double> = b ⊗ a
        #expect(lhsOperators == lhs && rhsOperators == rhs)
    }

    @Test("SR-539 selective: a ⊕ b is the better by < (ViterbiSemiring<Double>: a = 0.5, b = 0.25)")
    func sr539() {
        // a ⊕ b == (b < a ? b : a) → true (0.5)
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 0.5)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-540 idempotent (ViterbiSemiring<Double>: a = 0.5)")
    func sr540() {
        // a ⊕ a == a → true (a ⊕ a = 0.5)
        let a = ViterbiSemiring<Double>(0.5)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 0.5)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-541 selective: a ⊕ b is the better by < (ViterbiSemiring<Double>: a = 0.0, b = 0.75)")
    func sr541() {
        // a ⊕ b == (b < a ? b : a) → true (0.75)
        let a = ViterbiSemiring<Double>(0.0)
        let b = ViterbiSemiring<Double>(0.75)
        let sum = a.plus(b)
        #expect(sum == (b < a ? b : a))
        #expect(sum == a || sum == b)
        #expect(sum.value == 0.75)
        #expect((a ⊕ b) == sum)
    }

    @Test("SR-542 idempotent (ViterbiSemiring<Double>: a = 0.0)")
    func sr542() {
        // a ⊕ a == a → true (a ⊕ a = 0.0)
        let a = ViterbiSemiring<Double>(0.0)
        let sum = a.plus(a)
        #expect(sum == a)
        #expect(sum.value == 0.0)
        #expect((a ⊕ a) == sum)
    }

    @Test("SR-543 the natural order: < is ‘better’ (ViterbiSemiring<Double>: a = 0.5, b = 0.25)")
    func sr543() {
        // a < b → true
        let a = ViterbiSemiring<Double>(0.5)
        let b = ViterbiSemiring<Double>(0.25)
        #expect((a < b))
        // The natural order: a < b exactly when a.plus(b) == a and a != b.
        #expect((a < b) == (a.plus(b) == a && a != b))
        #expect(!(b < a) && a != b)
    }

    @Test("SR-544 zero is the greatest (worst) element (ViterbiSemiring<Double>: a = 0.5)")
    func sr544() {
        // a < .zero || a == .zero → true
        let a = ViterbiSemiring<Double>(0.5)
        #expect(a < .zero || a == .zero)
        #expect(!(ViterbiSemiring<Double>.zero < a))
        #expect(a.plus(.zero) == a)
    }
}
