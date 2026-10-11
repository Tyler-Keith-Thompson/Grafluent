// The semiring laws on the catalog's operands (SR-008 – SR-207): ⊕ associative and commutative,
// zero its identity, ⊗ associative with identity one, zero annihilating, ⊗ distributing from
// both sides, ⊗ commutative (true of all four, not required); selectivity and idempotence; and
// the natural order, a < b when a ⊕ b == a != b, with zero the worst element.
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
}
