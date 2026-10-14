// LexicographicSemiring, and properties with shrinking (swift-property-based) of MaxPlusSemiring,
// ViterbiSemiring and LexicographicSemiring: the constants, the zero normalization, the order,
// the laws on random values in both spellings, and the selective entry points against brute
// force over simple paths: shortest paths with the fewest edges among equals, the widest among
// the shortest, longest paths in a DAG, and most probable paths. The catalog rows of max-plus and
// Viterbi are in the generated files (SR-459 – SR-577). See README.md.

import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Semirings
import ShortestPaths
import Testing

@Suite("Semirings: the lexicographic product, and max-plus and Viterbi properties")
struct SemiringProductTests {
    @Test("Lexicographic: zero and one, the pair, its description and hashing")
    func lexicographicConstants() {
        typealias L = LexicographicSemiring<TropicalSemiring<Int>, TropicalSemiring<Int>>
        #expect(L.zero.first == .zero && L.zero.second == .zero)
        #expect(L.one.first == .one && L.one.second == .one)
        let pair = L(TropicalSemiring(3), TropicalSemiring(2))
        #expect(pair.first.value == 3 && pair.second.value == 2)
        #expect(pair.description == "(3, 2)")
        #expect(L.zero.description == "(\(Int.max), \(Int.max))")
        #expect(L.one < L.zero && pair < L.zero && L.one < pair)
        #expect(Set([L.zero, L(.zero, .zero), pair, L(TropicalSemiring(3), TropicalSemiring(2))]).count == 2)
    }

    @Test("Lexicographic: a pair with either component at zero is the zero, made or multiplied")
    func lexicographicNormalization() {
        typealias L = LexicographicSemiring<TropicalSemiring<Int>, BottleneckSemiring<Int>>
        #expect(L(TropicalSemiring(3), .zero) == .zero)
        #expect(L(.zero, BottleneckSemiring(5)) == .zero)
        #expect(L(TropicalSemiring(3), .zero).first == .zero)
        // A tropical sum landing on Int.max is the zero, so the product is the zero.
        let a = L(TropicalSemiring(Int.max - 3), BottleneckSemiring(5)), b = L(TropicalSemiring(3), BottleneckSemiring(9))
        #expect(a.times(b) == .zero)
        #expect(L(TropicalSemiring(1), BottleneckSemiring(5)).times(.zero) == .zero)
        #expect(L(TropicalSemiring(1), BottleneckSemiring(5)).times(L(TropicalSemiring(2), BottleneckSemiring(3))) == L(TropicalSemiring(3), BottleneckSemiring(3)))
    }

    @Test("Lexicographic: ⊕ keeps the better first, and on a tie the better second")
    func lexicographicOrder() {
        typealias L = LexicographicSemiring<TropicalSemiring<Int>, BottleneckSemiring<Int>>
        let short = L(TropicalSemiring(3), BottleneckSemiring(1)), long = L(TropicalSemiring(4), BottleneckSemiring(9))
        let wide = L(TropicalSemiring(3), BottleneckSemiring(7))
        #expect(short.plus(long) == short && long.plus(short) == short)
        #expect(short.plus(wide) == wide && wide.plus(short) == wide)
        #expect(wide < short && short < long && wide < long)
        #expect(!(short < short) && short.plus(short) == short)
        let sum = short ⊕ wide, product = short ⊗ long
        #expect(sum == wide && product == L(TropicalSemiring(7), BottleneckSemiring(1)))
    }

    @Test("Lexicographic: a bottleneck first breaks distributivity, as documented")
    func lexicographicBottleneckFirst() {
        typealias L = LexicographicSemiring<BottleneckSemiring<Int>, TropicalSemiring<Int>>
        // A narrow edge c ties a wide path a with a narrower b.
        let a = L(BottleneckSemiring(5), TropicalSemiring(9)), b = L(BottleneckSemiring(3), TropicalSemiring(1))
        let c = L(BottleneckSemiring(1), TropicalSemiring(0))
        #expect(a.plus(b).times(c) == L(BottleneckSemiring(1), TropicalSemiring(9)))
        #expect(a.times(c).plus(b.times(c)) == L(BottleneckSemiring(1), TropicalSemiring(1)))
    }

    @Test("The laws on random values: max-plus, Viterbi and lexicographic products, both spellings", .tags(.randomized))
    func laws() async {
        func check<S: SelectiveSemiring & Hashable>(_ a: S, _ b: S, _ c: S) {
            let context = "\(a) \(b) \(c)"
            #expect(a.plus(b).plus(c) == a.plus(b.plus(c)), "⊕ associative: \(context)")
            #expect(a.plus(b) == b.plus(a), "⊕ commutative: \(context)")
            #expect(a.plus(.zero) == a && S.zero.plus(a) == a, "zero is ⊕'s identity: \(context)")
            #expect(a.times(b).times(c) == a.times(b.times(c)), "⊗ associative: \(context)")
            #expect(a.times(.one) == a && S.one.times(a) == a, "one is ⊗'s identity: \(context)")
            #expect(a.times(.zero) == .zero && S.zero.times(a) == .zero, "zero annihilates: \(context)")
            #expect(a.times(b.plus(c)) == a.times(b).plus(a.times(c)), "left distributive: \(context)")
            #expect(a.plus(b).times(c) == a.times(c).plus(b.times(c)), "right distributive: \(context)")
            #expect(a.plus(b) == (b < a ? b : a), "selective: \(context)")
            #expect((a < b) == (a.plus(b) == a && a != b), "natural order: \(context)")
            #expect([a < b, b < a, a == b].filter { $0 }.count == 1, "trichotomy: \(context)")
            #expect(!(S.zero < a), "zero is the worst: \(context)")
            let sum = a ⊕ b, product = a ⊗ b
            #expect(sum == a.plus(b) && product == a.times(b), "operators: \(context)")
            if a == b { #expect(a.hashValue == b.hashValue, "hash: \(context)") }
        }
        // Int.min is the max-plus zero.
        let maxPlusInt = Gen.int(in: -60 ... 50).map { $0 < -50 ? Int.min : $0 }
        await propertyCheck(count: 400, input: maxPlusInt, maxPlusInt, maxPlusInt) { a, b, c in
            check(MaxPlusSemiring(a), MaxPlusSemiring(b), MaxPlusSemiring(c))
        }
        let maxPlusDouble = Gen.int(in: -210 ... 200).map { $0 < -200 ? -Double.infinity : Double($0) / 4 }
        await propertyCheck(count: 400, input: maxPlusDouble, maxPlusDouble, maxPlusDouble) { a, b, c in
            check(MaxPlusSemiring(a), MaxPlusSemiring(b), MaxPlusSemiring(c))
        }
        // Powers of two, so products are exact.
        let viterbi = Gen.int(in: 0 ... 8).map { $0 == 0 ? 0.0 : 1.0 / Double(1 << ($0 - 1)) }
        await propertyCheck(count: 400, input: viterbi, viterbi, viterbi) { a, b, c in
            check(ViterbiSemiring(a), ViterbiSemiring(b), ViterbiSemiring(c))
        }
        // Tropical first, any selective second; zeros included on both sides.
        let first = Gen.int(in: -8 ... 12).map { $0 > 10 ? Int.max : $0 }
        let second = Gen.int(in: -8 ... 12).map { $0 > 10 ? Int.min : $0 }
        await propertyCheck(count: 400, input: zip(first, second), zip(first, second), zip(first, second)) { a, b, c in
            typealias L = LexicographicSemiring<TropicalSemiring<Int>, BottleneckSemiring<Int>>
            check(L(TropicalSemiring(a.0), BottleneckSemiring(a.1)), L(TropicalSemiring(b.0), BottleneckSemiring(b.1)), L(TropicalSemiring(c.0), BottleneckSemiring(c.1)))
        }
        await propertyCheck(count: 400, input: zip(first, second), zip(first, second), zip(first, second)) { a, b, c in
            typealias L = LexicographicSemiring<MaxPlusSemiring<Int>, TropicalSemiring<Int>>
            func pair(_ x: (Int, Int)) -> L { L(MaxPlusSemiring(x.0 == Int.max ? Int.min : x.0), TropicalSemiring(x.1 == Int.min ? Int.max : x.1)) }
            check(pair(a), pair(b), pair(c))
        }
    }

    @Test("Selective entry points against brute force over simple paths: lexicographic, max-plus and Viterbi", .tags(.randomized))
    func againstBruteForce() async {
        // Up to 12 edges on 5 vertices, weights 0...3 (ties are common), loops and parallel edges.
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 3)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges) { raw in
            let graph = DirectedPseudograph(vertices: 0 ..< 5, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Every simple path from 0, as its edges.
            var paths: [[Int]] = []
            var onPath = [0]
            var steps: [Int] = []
            func extend(_ u: Int) {
                paths.append(steps)
                for (k, e) in raw.enumerated() where e.0 == u && !onPath.contains(e.1) {
                    onPath.append(e.1)
                    steps.append(k)
                    extend(e.1)
                    steps.removeLast()
                    onPath.removeLast()
                }
            }
            extend(0)
            func target(_ path: [Int]) -> Int { path.last.map { raw[$0].1 } ?? 0 }
            // Shortest, then fewest edges.
            typealias Hops = LexicographicSemiring<TropicalSemiring<Int>, TropicalSemiring<Int>>
            let hops = graph.dijkstraShortestPaths(from: 0) { Hops(TropicalSemiring(raw[$0].2), TropicalSemiring(1)) }
            // Shortest, then widest (width = the weight + 1, so every edge has some).
            typealias Wide = LexicographicSemiring<TropicalSemiring<Int>, BottleneckSemiring<Int>>
            let wide = graph.dijkstraShortestPaths(from: 0) { Wide(TropicalSemiring(raw[$0].2), BottleneckSemiring(raw[$0].2 + 1)) }
            let bellman = graph.bellmanFordShortestPaths(from: 0) { Hops(TropicalSemiring(raw[$0].2), TropicalSemiring(1)) }
            // Most probable, with probability 2^-w.
            let probable = graph.dijkstraShortestPaths(from: 0) { ViterbiSemiring(1.0 / Double(1 << raw[$0].2)) }
            for v in 0 ..< 5 {
                let into = paths.filter { target($0) == v }
                let lengths = into.map { $0.map { raw[$0].2 }.reduce(0, +) }
                guard let best = lengths.min() else {
                    #expect(hops.distance(to: v) == nil && wide.distance(to: v) == nil && probable.distance(to: v) == nil)
                    continue
                }
                let shortest = into.filter { $0.map { raw[$0].2 }.reduce(0, +) == best }
                let fewest = shortest.map(\.count).min()!
                let widest = shortest.map { $0.map { raw[$0].2 + 1 }.min() ?? Int.max }.max()!
                #expect(hops.distance(to: v) == Hops(TropicalSemiring(best), TropicalSemiring(fewest)), "\(raw) to \(v)")
                #expect(bellman?.distance(to: v) == Hops(TropicalSemiring(best), TropicalSemiring(fewest)), "\(raw) to \(v)")
                #expect(wide.distance(to: v) == Wide(TropicalSemiring(best), BottleneckSemiring(widest)), "\(raw) to \(v)")
                #expect(probable.distance(to: v)?.value == 1.0 / Double(1 << best), "\(raw) to \(v)")
                // The tree's path weighs its distance.
                let path = hops.path(to: v)!
                #expect(path.edges.count == fewest && path.edges.map { raw[$0].2 }.reduce(0, +) == best)
            }
        }
    }

    @Test("Longest paths in a DAG over max-plus, against brute force", .tags(.randomized))
    func longestPathsInADAG() async {
        // Edges low → high on 6 vertices, weights −3...6.
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: -3 ... 6)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: edges) { raw in
            let arcs = raw.filter { $0.0 != $0.1 }.map { (min($0.0, $0.1), max($0.0, $0.1), $0.2) }
            let graph = DirectedPseudograph(vertices: 0 ..< 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            var longest = [Int?](repeating: nil, count: 6)
            longest[0] = 0
            func extend(_ u: Int, _ length: Int) {
                for e in arcs where e.0 == u {
                    let total = length + e.2
                    if longest[e.1].map({ total > $0 }) ?? true { longest[e.1] = total }
                    extend(e.1, total)
                }
            }
            extend(0, 0)
            let tree = graph.dagShortestPaths(from: 0) { MaxPlusSemiring(arcs[$0].2) }
            #expect((0 ..< 6).map { tree?.distance(to: $0)?.value } == longest, "\(arcs)")
            let maintained = DirectedAcyclicGraph(graph)!.dagShortestPaths(from: 0) { MaxPlusSemiring(arcs[$0].2) }
            #expect((0 ..< 6).map { maintained.distance(to: $0)?.value } == longest, "\(arcs)")
            // Bellman–Ford agrees: an acyclic graph has no positive cycle.
            let bellman = graph.bellmanFordShortestPaths(from: 0) { MaxPlusSemiring(arcs[$0].2) }
            #expect((0 ..< 6).map { bellman?.distance(to: $0)?.value } == longest, "\(arcs)")
        }
    }
}
