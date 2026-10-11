// Cycle detection over a closure (catalog FG-047 – FG-059): the tail length, cycle length and root,
// and the exact closure call counts of the formulations api.md pins.
// Generated from cases.md by swiftgen.py; see README.md.

import FunctionalGraphs
import GraphProtocols
import Testing

@Suite("FunctionalGraphs Floyd and Brent")
struct FunctionalGraphCycleDetectionTests {
    @Test("FG-047 a fixed point at the start")
    func fg047() {
        // f = { $0 } / floydCycleDetection(from: 7, successor: f) / calls / brentCycleDetection(from: 7, successor: f) / calls
        // → (tail 0, cycle 1, root 7); 4; (tail 0, cycle 1, root 7); 2
        let f: (Int) -> Int = { $0 }
        var calls = 0
        let floyd = floydCycleDetection(from: 7, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 0 && floyd.cycleLength == 1 && floyd.root == 7)
        #expect(calls == 4)
        calls = 0
        let brent = brentCycleDetection(from: 7, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 0 && brent.cycleLength == 1 && brent.root == 7)
        #expect(calls == 2)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 7
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 7
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-048 start on a 5-cycle")
    func fg048() {
        // f = { ($0 + 1) % 5 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls
        // → (tail 0, cycle 5, root 0); 20; (tail 0, cycle 5, root 0); 17
        let f: (Int) -> Int = { ($0 + 1) % 5 }
        var calls = 0
        let floyd = floydCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 0 && floyd.cycleLength == 5 && floyd.root == 0)
        #expect(calls == 20)
        calls = 0
        let brent = brentCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 0 && brent.cycleLength == 5 && brent.root == 0)
        #expect(calls == 17)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 0
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 0
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-049 a 2-cycle at the start")
    func fg049() {
        // f = { 1 - $0 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls
        // → (tail 0, cycle 2, root 0); 8; (tail 0, cycle 2, root 0); 5
        let f: (Int) -> Int = { 1 - $0 }
        var calls = 0
        let floyd = floydCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 0 && floyd.cycleLength == 2 && floyd.root == 0)
        #expect(calls == 8)
        calls = 0
        let brent = brentCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 0 && brent.cycleLength == 2 && brent.root == 0)
        #expect(calls == 5)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 0
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 0
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-050 one step into a fixed point")
    func fg050() {
        // f = { _ in 0 } / floydCycleDetection(from: 5, successor: f) / calls / brentCycleDetection(from: 5, successor: f) / calls
        // → (tail 1, cycle 1, root 0); 6; (tail 1, cycle 1, root 0); 5
        let f: (Int) -> Int = { _ in 0 }
        var calls = 0
        let floyd = floydCycleDetection(from: 5, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 1 && floyd.cycleLength == 1 && floyd.root == 0)
        #expect(calls == 6)
        calls = 0
        let brent = brentCycleDetection(from: 5, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 1 && brent.cycleLength == 1 && brent.root == 0)
        #expect(calls == 5)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 5
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 5
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-051 the featured graph from 2 (tail 3 into a 3-cycle)")
    func fg051() {
        // f = { [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8][$0] } / floydCycleDetection(from: 2, successor: f) / calls / brentCycleDetection(from: 2, successor: f) / calls
        // → (tail 3, cycle 3, root 3); 18; (tail 3, cycle 3, root 3); 15
        let f: (Int) -> Int = { [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8][$0] }
        var calls = 0
        let floyd = floydCycleDetection(from: 2, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 3 && floyd.cycleLength == 3 && floyd.root == 3)
        #expect(calls == 18)
        calls = 0
        let brent = brentCycleDetection(from: 2, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 3 && brent.cycleLength == 3 && brent.root == 3)
        #expect(calls == 15)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 2
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 2
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-052 the featured graph from 11")
    func fg052() {
        // f = { [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8][$0] } / floydCycleDetection(from: 11, successor: f) / calls / brentCycleDetection(from: 11, successor: f) / calls
        // → (tail 2, cycle 2, root 9); 12; (tail 2, cycle 2, root 9); 11
        let f: (Int) -> Int = { [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8][$0] }
        var calls = 0
        let floyd = floydCycleDetection(from: 11, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 2 && floyd.cycleLength == 2 && floyd.root == 9)
        #expect(calls == 12)
        calls = 0
        let brent = brentCycleDetection(from: 11, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 2 && brent.cycleLength == 2 && brent.root == 9)
        #expect(calls == 11)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 11
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 11
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-053 Pollard's rho: x² + 1 mod 1 000")
    func fg053() {
        // f = { ($0 * $0 + 1) % 1_000 } / floydCycleDetection(from: 3, successor: f) / calls / brentCycleDetection(from: 3, successor: f) / calls
        // → (tail 5, cycle 6, root 26); 34; (tail 5, cycle 6, root 26); 29
        let f: (Int) -> Int = { ($0 * $0 + 1) % 1_000 }
        var calls = 0
        let floyd = floydCycleDetection(from: 3, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 5 && floyd.cycleLength == 6 && floyd.root == 26)
        #expect(calls == 34)
        calls = 0
        let brent = brentCycleDetection(from: 3, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 5 && brent.cycleLength == 6 && brent.root == 26)
        #expect(calls == 29)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 3
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 3
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-054 Pollard's rho: x² + 1 mod 8 051 (= 83·97)")
    func fg054() {
        // f = { ($0 * $0 + 1) % 8_051 } / floydCycleDetection(from: 2, successor: f) / calls / brentCycleDetection(from: 2, successor: f) / calls
        // → (tail 4, cycle 15, root 7474); 68; (tail 4, cycle 15, root 7474); 53
        let f: (Int) -> Int = { ($0 * $0 + 1) % 8_051 }
        var calls = 0
        let floyd = floydCycleDetection(from: 2, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 4 && floyd.cycleLength == 15 && floyd.root == 7474)
        #expect(calls == 68)
        calls = 0
        let brent = brentCycleDetection(from: 2, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 4 && brent.cycleLength == 15 && brent.root == 7474)
        #expect(calls == 53)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 2
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 2
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-055 Collatz from 27: tail 109 into 4 → 2 → 1")
    func fg055() {
        // f = { $0 % 2 == 0 ? $0 / 2 : 3 * $0 + 1 } / floydCycleDetection(from: 27, successor: f) / calls / brentCycleDetection(from: 27, successor: f) / calls
        // → (tail 109, cycle 3, root 4); 554; (tail 109, cycle 3, root 4); 351
        let f: (Int) -> Int = { $0 % 2 == 0 ? $0 / 2 : 3 * $0 + 1 }
        var calls = 0
        let floyd = floydCycleDetection(from: 27, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 109 && floyd.cycleLength == 3 && floyd.root == 4)
        #expect(calls == 554)
        calls = 0
        let brent = brentCycleDetection(from: 27, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 109 && brent.cycleLength == 3 && brent.root == 4)
        #expect(calls == 351)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 27
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 27
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-056 long tail, short cycle: 100 steps into a 1-cycle")
    func fg056() {
        // f = { min($0 + 1, 100) } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls
        // → (tail 100, cycle 1, root 100); 501; (tail 100, cycle 1, root 100); 329
        let f: (Int) -> Int = { min($0 + 1, 100) }
        var calls = 0
        let floyd = floydCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 100 && floyd.cycleLength == 1 && floyd.root == 100)
        #expect(calls == 501)
        calls = 0
        let brent = brentCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 100 && brent.cycleLength == 1 && brent.root == 100)
        #expect(calls == 329)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 0
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 0
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-057 short tail, long cycle: 1 step into a 100-cycle")
    func fg057() {
        // f = { $0 == 0 ? 1 : $0 % 100 + 1 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls
        // → (tail 1, cycle 100, root 1); 402; (tail 1, cycle 100, root 1); 329
        let f: (Int) -> Int = { $0 == 0 ? 1 : $0 % 100 + 1 }
        var calls = 0
        let floyd = floydCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 1 && floyd.cycleLength == 100 && floyd.root == 1)
        #expect(calls == 402)
        calls = 0
        let brent = brentCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 1 && brent.cycleLength == 100 && brent.root == 1)
        #expect(calls == 329)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 0
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 0
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-058 a cycle of length 2^k + 1 (Brent's power doubling boundary)")
    func fg058() {
        // f = { ($0 + 1) % 17 } / floydCycleDetection(from: 0, successor: f) / calls / brentCycleDetection(from: 0, successor: f) / calls
        // → (tail 0, cycle 17, root 0); 68; (tail 0, cycle 17, root 0); 65
        let f: (Int) -> Int = { ($0 + 1) % 17 }
        var calls = 0
        let floyd = floydCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 0 && floyd.cycleLength == 17 && floyd.root == 0)
        #expect(calls == 68)
        calls = 0
        let brent = brentCycleDetection(from: 0, successor: { (x: Int) -> Int in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 0 && brent.cycleLength == 17 && brent.root == 0)
        #expect(calls == 65)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = 0
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = 0
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }

    @Test("FG-059 Equatable states that are not Int: Fibonacci pairs mod 10, Pisano period 60")
    func fg059() {
        // struct Pair: Equatable { var a, b: Int }; f = { Pair(a: $0.b, b: ($0.a + $0.b) % 10) } / floydCycleDetection(from: Pair(a: 0, b: 1), successor: f) / calls / brentCycleDetection(from: Pair(a: 0, b: 1), successor: f) / calls
        // → (tail 0, cycle 60, root Pair(a: 0, b: 1)); 240; (tail 0, cycle 60, root Pair(a: 0, b: 1)); 183
        struct Pair: Equatable {
            var a, b: Int
        }
        let f: (Pair) -> Pair = { Pair(a: $0.b, b: ($0.a + $0.b) % 10) }
        var calls = 0
        let floyd = floydCycleDetection(from: Pair(a: 0, b: 1), successor: { (x: Pair) -> Pair in
            calls += 1
            return f(x)
        })
        #expect(floyd.tailLength == 0 && floyd.cycleLength == 60 && floyd.root == Pair(a: 0, b: 1))
        #expect(calls == 240)
        calls = 0
        let brent = brentCycleDetection(from: Pair(a: 0, b: 1), successor: { (x: Pair) -> Pair in
            calls += 1
            return f(x)
        })
        #expect(brent.tailLength == 0 && brent.cycleLength == 60 && brent.root == Pair(a: 0, b: 1))
        #expect(calls == 183)
        // The definition, by walking f: the root is tailLength steps out and on a cycle of
        // cycleLength; the vertex before it is not on the cycle.
        var x = Pair(a: 0, b: 1)
        for _ in 0 ..< floyd.tailLength { x = f(x) }
        #expect(x == floyd.root)
        var y = f(x)
        var length = 1
        while y != x {
            y = f(y)
            length += 1
        }
        #expect(length == floyd.cycleLength)
        if floyd.tailLength > 0 {
            var before = Pair(a: 0, b: 1)
            for _ in 1 ..< floyd.tailLength { before = f(before) }
            var after = before
            for _ in 0 ..< floyd.cycleLength { after = f(after) }
            #expect(after != before)
        }
    }
}
