// The generator (catalog RG-001 – RG-008): xoshiro256** from a given state reproduces rand_xoshiro's
// test vector; init(seed:) fills the state from SplitMix64; a copy replays the stream; the
// standard library's random APIs accept it.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import RandomGraphs
import Testing

@Suite("RandomGraphs generator")
struct GeneratorTests {
    @Test("RG-001 xoshiro256** reference vector (rand_xoshiro's test)")
    func rg001() {
        // Xoshiro256StarStar(state: (1, 2, 3, 4)); next() × 4 → [11520, 0, 1509978240, 1215971899390074240]
        var generator = Xoshiro256StarStar(state: (1, 2, 3, 4))
        #expect((0 ..< 4).map { _ in generator.next() } == [11520, 0, 1509978240, 1215971899390074240] as [UInt64])
    }

    @Test("RG-003 seed 0: SplitMix64 fills the state")
    func rg003() {
        // Xoshiro256StarStar(seed: 0); next() × 4 → [11091344671253066420, 13793997310169335082, 1900383378846508768, 7684712102626143532]
        var generator = Xoshiro256StarStar(seed: 0)
        #expect((0 ..< 4).map { _ in generator.next() } == [11091344671253066420, 13793997310169335082, 1900383378846508768, 7684712102626143532] as [UInt64])
    }

    @Test("RG-004 seed 1: SplitMix64 fills the state")
    func rg004() {
        // Xoshiro256StarStar(seed: 1); next() × 4 → [12966619160104079557, 9600361134598540522, 10590380919521690900, 7218738570589545383]
        var generator = Xoshiro256StarStar(seed: 1)
        #expect((0 ..< 4).map { _ in generator.next() } == [12966619160104079557, 9600361134598540522, 10590380919521690900, 7218738570589545383] as [UInt64])
    }

    @Test("RG-005 seed 42: SplitMix64 fills the state")
    func rg005() {
        // Xoshiro256StarStar(seed: 42); next() × 4 → [1546998764402558742, 6990951692964543102, 12544586762248559009, 17057574109182124193]
        var generator = Xoshiro256StarStar(seed: 42)
        #expect((0 ..< 4).map { _ in generator.next() } == [1546998764402558742, 6990951692964543102, 12544586762248559009, 17057574109182124193] as [UInt64])
    }

    @Test("RG-006 seed 18446744073709551615: SplitMix64 fills the state")
    func rg006() {
        // Xoshiro256StarStar(seed: 18446744073709551615); next() × 4 → [10328197420357168392, 14156678507024973869, 9357971779955476126, 13791585006304312367]
        var generator = Xoshiro256StarStar(seed: 18446744073709551615)
        #expect((0 ..< 4).map { _ in generator.next() } == [10328197420357168392, 14156678507024973869, 9357971779955476126, 13791585006304312367] as [UInt64])
    }

    @Test("RG-007 a copy replays the stream (value semantics)")
    func rg007() {
        // var a = Xoshiro256StarStar(seed: 5); var b = a; a.next() × 3; b.next() × 3 → both [5320248114040590185, 11106458710588138716, 11982022302389484462]
        var a = Xoshiro256StarStar(seed: 5)
        var b = a
        #expect(a == b)
        let first = (0 ..< 3).map { _ in a.next() }
        #expect(a != b)
        let second = (0 ..< 3).map { _ in b.next() }
        #expect(first == [5320248114040590185, 11106458710588138716, 11982022302389484462] as [UInt64])
        #expect(second == first)
        #expect(a == b && a.hashValue == b.hashValue)
    }

    @Test("RG-008 works with any RandomNumberGenerator API (values not pinned)")
    func rg008() {
        // Int.random(in: 1...6, using: &g) → in 1...6; not compared: the standard library's algorithm is not ours to pin
        var generator = Xoshiro256StarStar(seed: 8)
        for _ in 0 ..< 1000 {
            #expect((1 ... 6).contains(Int.random(in: 1 ... 6, using: &generator)))
            let x = Double.random(in: 0 ..< 1, using: &generator)
            #expect(x >= 0 && x < 1)
        }
        #expect(Array(0 ..< 10).shuffled(using: &generator).sorted() == Array(0 ..< 10))
        #expect([1, 2, 3].randomElement(using: &generator) != nil)
    }
}
