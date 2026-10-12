// Isomorphism, subgraph isomorphism and monomorphism against brute force over every injection, on
// small multigraphs with loops and parallel edges (at most 7 target vertices), directed and
// undirected, with optional vertex and edge colours: the yes/no answer, the first mapping and the
// whole sequence (its count, no mapping twice, each one valid by the definition). Relabelled
// copies (vertices listed in another order, edges inserted in another order, labels changed) are
// always isomorphic, and have equal Weisfeiler–Leman graph hashes and per-vertex hashes. The
// automorphism group (order, orbits, generators) against brute force, with each colour overload;
// canonical forms equal exactly when two graphs are isomorphic.

import FuzzSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs

@main
enum FuzzIsomorphism {
    static func main() { runFuzzer(fuzz) }

    /// A graph as the fuzzer drew it: vertex labels in `vertices` order, edges by position as
    /// pairs of positions in `vertices`, a colour per vertex and per edge.
    struct Drawn {
        var labels: [Int]
        var edges: [(Int, Int)]
        var vertexColors: [Int]
        var edgeColors: [Int]
    }

    static func draw(_ input: inout FuzzInput, vertices n: Int, maxEdges: Int, vertexKinds: Int, edgeKinds: Int, labelBase: Int) -> Drawn {
        let m = input.int(below: maxEdges + 1)
        var edges: [(Int, Int)] = []
        if n > 0 {
            for _ in 0 ..< m {
                // A bias towards repeating the previous pair, for parallel edges.
                if !edges.isEmpty, input.int(below: 4) == 0 {
                    edges.append(edges[edges.count - 1])
                } else {
                    edges.append((input.int(below: n), input.int(below: n)))
                }
            }
        }
        return Drawn(
            labels: (0 ..< n).map { labelBase + 3 * $0 },
            edges: edges,
            vertexColors: (0 ..< n).map { _ in input.int(below: vertexKinds) },
            edgeColors: edges.map { _ in input.int(below: edgeKinds) }
        )
    }

    /// The same graph relabelled by a permutation drawn from the input, its vertices listed and
    /// its edges inserted in other orders (an undirected edge may also swap its ends). Returns
    /// the copy and, by position in `d.labels`, the position of each vertex's image in the copy.
    static func relabel(_ input: inout FuzzInput, _ d: Drawn, directed: Bool) -> (Drawn, [Int]) {
        let n = d.labels.count
        var perm = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { perm.swapAt(i, input.int(below: i + 1)) }
        // Old vertex i becomes copy vertex perm[i]; the copy's vertex j has label 1000 + 7j.
        var vertexColors = [Int](repeating: 0, count: n)
        for i in 0 ..< n { vertexColors[perm[i]] = d.vertexColors[i] }
        var order = Array(d.edges.indices)
        for i in stride(from: order.count - 1, to: 0, by: -1) { order.swapAt(i, input.int(below: i + 1)) }
        var edges: [(Int, Int)] = [], edgeColors: [Int] = []
        for k in order {
            let (a, b) = d.edges[k]
            if !directed && input.int(below: 2) == 0 {
                edges.append((perm[b], perm[a]))
            } else {
                edges.append((perm[a], perm[b]))
            }
            edgeColors.append(d.edgeColors[k])
        }
        return (Drawn(labels: (0 ..< n).map { 1000 + 7 * $0 }, edges: edges, vertexColors: vertexColors, edgeColors: edgeColors), perm)
    }

    // MARK: the definitions

    /// By ordered pair of positions (a * n + b): the sorted colours of the edges between them,
    /// in both orders for an undirected edge (a loop once).
    static func pairColors(_ d: Drawn, directed: Bool) -> [[Int]] {
        let n = d.labels.count
        var table = [[Int]](repeating: [], count: n * n)
        for (k, (a, b)) in d.edges.enumerated() {
            table[a * n + b].append(d.edgeColors[k])
            if !directed && a != b { table[b * n + a].append(d.edgeColors[k]) }
        }
        return table.map { $0.sorted() }
    }

    static func isSubMultiset(_ small: [Int], _ large: [Int]) -> Bool {
        var counts: [Int: Int] = [:]
        for c in large { counts[c, default: 0] += 1 }
        for c in small {
            guard let k = counts[c], k > 0 else { return false }
            counts[c] = k - 1
        }
        return true
    }

    enum Kind { case isomorphism, induced, mono }

    /// Whether `images` (pattern position → target position) is a mapping of `kind`.
    static func valid(_ images: [Int], _ p: Drawn, _ t: Drawn, _ pp: [[Int]], _ tp: [[Int]], _ kind: Kind, colored: Bool) -> Bool {
        let np = p.labels.count, nt = t.labels.count
        if images.count != np { return false }
        if Set(images).count != np || images.contains(where: { $0 < 0 || $0 >= nt }) { return false }
        if kind == .isomorphism && np != nt { return false }
        for u in 0 ..< np where colored && p.vertexColors[u] != t.vertexColors[images[u]] { return false }
        for u in 0 ..< np {
            for v in 0 ..< np {
                var a = pp[u * np + v], b = tp[images[u] * nt + images[v]]
                if !colored {
                    a = a.map { _ in 0 }
                    b = b.map { _ in 0 }
                }
                if kind == .mono ? !isSubMultiset(a, b) : a != b { return false }
            }
        }
        return true
    }

    /// Every valid mapping, by trying every injection.
    static func bruteForce(_ p: Drawn, _ t: Drawn, _ kind: Kind, directed: Bool, colored: Bool) -> Set<[Int]> {
        let np = p.labels.count, nt = t.labels.count
        let pp = pairColors(p, directed: directed), tp = pairColors(t, directed: directed)
        var found = Set<[Int]>()
        var images: [Int] = [], used = [Bool](repeating: false, count: nt)
        func extend() {
            if images.count == np {
                if valid(images, p, t, pp, tp, kind, colored: colored) { found.insert(images) }
                return
            }
            for x in 0 ..< nt where !used[x] {
                used[x] = true
                images.append(x)
                extend()
                images.removeLast()
                used[x] = false
            }
        }
        if kind != .isomorphism || np == nt { extend() }
        return found
    }

    // MARK: the graphs

    static func undirected(_ d: Drawn) -> Pseudograph<Int> {
        Pseudograph(vertices: d.labels, edges: d.edges.map { UndirectedEdge(d.labels[$0.0], d.labels[$0.1]) })
    }

    static func directed(_ d: Drawn) -> DirectedPseudograph<Int> {
        DirectedPseudograph(vertices: d.labels, edges: d.edges.map { DirectedEdge(from: d.labels[$0.0], to: d.labels[$0.1]) })
    }

    /// The pattern positions of a returned mapping's images.
    static func positions(_ images: some Sequence<Int>, _ t: Drawn) -> [Int] {
        images.map { label in t.labels.firstIndex(of: label) ?? -1 }
    }

    /// Checks one problem: `all` is the sequence, `first` the first mapping, `yes` the answer,
    /// each as image labels in the pattern's vertex order.
    static func compare(_ name: String, _ expected: Set<[Int]>, _ t: Drawn, all: [[Int]], first: [Int]?, yes: Bool) {
        let mapped = all.map { positions($0, t) }
        check(Set(mapped).count == mapped.count, "\(name): a mapping appears twice")
        for m in mapped { check(expected.contains(m), "\(name): \(m) is not a mapping") }
        check(mapped.count == expected.count, "\(name): \(mapped.count) mappings, expected \(expected.count)")
        check(yes == !expected.isEmpty, "\(name): yes/no \(yes), expected \(!expected.isEmpty)")
        check(first.map { positions($0, t) } == mapped.first, "\(name): the first mapping is not the sequence's first")
    }

    static func checkUndirected(_ p: Drawn, _ t: Drawn, colors: Int) {
        let g = undirected(p), h = undirected(t)
        let pv = Dictionary(uniqueKeysWithValues: zip(p.labels, p.vertexColors)), tv = Dictionary(uniqueKeysWithValues: zip(t.labels, t.vertexColors))
        for kind in [Kind.isomorphism, .induced, .mono] {
            for colored in colors == 0 ? [false] : [false, true] {
                let expected = bruteForce(p, t, kind, directed: false, colored: colored)
                let name = "undirected \(kind) colored \(colored) (vertex colours \(colors == 1 ? "only" : "and edge"))"
                let all: [[Int]], first: [Int]?, yes: Bool
                switch (kind, colored, colors) {
                case (.isomorphism, false, _):
                    all = g.isomorphisms(to: h).map { Array($0.images) }
                    first = g.isomorphism(to: h).map { Array($0.images) }
                    yes = g.isIsomorphic(to: h)
                case (.induced, false, _):
                    all = g.subgraphIsomorphisms(to: h).map { Array($0.images) }
                    first = g.subgraphIsomorphism(to: h).map { Array($0.images) }
                    yes = g.isSubgraphIsomorphic(to: h)
                case (.mono, false, _):
                    all = g.monomorphisms(to: h).map { Array($0.images) }
                    first = g.monomorphism(to: h).map { Array($0.images) }
                    yes = g.isMonomorphic(to: h)
                case (.isomorphism, true, 1):
                    all = g.isomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    first = g.isomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    yes = g.isIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! })
                case (.induced, true, 1):
                    all = g.subgraphIsomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    first = g.subgraphIsomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    yes = g.isSubgraphIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! })
                case (.mono, true, 1):
                    all = g.monomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    first = g.monomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    yes = g.isMonomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! })
                case (.isomorphism, true, _):
                    all = g.isomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    first = g.isomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    yes = g.isIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] })
                case (.induced, true, _):
                    all = g.subgraphIsomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    first = g.subgraphIsomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    yes = g.isSubgraphIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] })
                case (.mono, true, _):
                    all = g.monomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    first = g.monomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    yes = g.isMonomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] })
                }
                compare(name, expected, t, all: all, first: first, yes: yes)
            }
        }
    }

    static func checkDirected(_ p: Drawn, _ t: Drawn, colors: Int) {
        let g = directed(p), h = directed(t)
        let pv = Dictionary(uniqueKeysWithValues: zip(p.labels, p.vertexColors)), tv = Dictionary(uniqueKeysWithValues: zip(t.labels, t.vertexColors))
        for kind in [Kind.isomorphism, .induced, .mono] {
            for colored in colors == 0 ? [false] : [false, true] {
                let expected = bruteForce(p, t, kind, directed: true, colored: colored)
                let name = "directed \(kind) colored \(colored) (vertex colours \(colors == 1 ? "only" : "and edge"))"
                let all: [[Int]], first: [Int]?, yes: Bool
                switch (kind, colored, colors) {
                case (.isomorphism, false, _):
                    all = g.isomorphisms(to: h).map { Array($0.images) }
                    first = g.isomorphism(to: h).map { Array($0.images) }
                    yes = g.isIsomorphic(to: h)
                case (.induced, false, _):
                    all = g.subgraphIsomorphisms(to: h).map { Array($0.images) }
                    first = g.subgraphIsomorphism(to: h).map { Array($0.images) }
                    yes = g.isSubgraphIsomorphic(to: h)
                case (.mono, false, _):
                    all = g.monomorphisms(to: h).map { Array($0.images) }
                    first = g.monomorphism(to: h).map { Array($0.images) }
                    yes = g.isMonomorphic(to: h)
                case (.isomorphism, true, 1):
                    all = g.isomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    first = g.isomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    yes = g.isIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! })
                case (.induced, true, 1):
                    all = g.subgraphIsomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    first = g.subgraphIsomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    yes = g.isSubgraphIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! })
                case (.mono, true, 1):
                    all = g.monomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    first = g.monomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }).map { Array($0.images) }
                    yes = g.isMonomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! })
                case (.isomorphism, true, _):
                    all = g.isomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    first = g.isomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    yes = g.isIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] })
                case (.induced, true, _):
                    all = g.subgraphIsomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    first = g.subgraphIsomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    yes = g.isSubgraphIsomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] })
                case (.mono, true, _):
                    all = g.monomorphisms(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    first = g.monomorphism(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] }).map { Array($0.images) }
                    yes = g.isMonomorphic(to: h, vertexColor: { pv[$0]! }, otherVertexColor: { tv[$0]! }, edgeColor: { p.edgeColors[$0] }, otherEdgeColor: { t.edgeColors[$0] })
                }
                compare(name, expected, t, all: all, first: first, yes: yes)
            }
        }
    }

    /// Weisfeiler–Leman on a relabelled copy: equal graph hashes and, vertex by vertex through
    /// the relabelling, equal per-vertex hashes, in every overload.
    static func checkHashes(_ d: Drawn, _ copy: Drawn, _ perm: [Int], directed isDirected: Bool, iterations: Int) {
        let dv = Dictionary(uniqueKeysWithValues: zip(d.labels, d.vertexColors)), cv = Dictionary(uniqueKeysWithValues: zip(copy.labels, copy.vertexColors))
        let a: [Int], b: [Int]
        let ar: [[[Int]]], br: [[[Int]]]
        if isDirected {
            let g = directed(d), h = directed(copy)
            a = [g.weisfeilerLehmanGraphHash(iterations: iterations), g.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { dv[$0]! }), g.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { dv[$0]! }, edgeColor: { d.edgeColors[$0] })]
            b = [h.weisfeilerLehmanGraphHash(iterations: iterations), h.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { cv[$0]! }), h.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { cv[$0]! }, edgeColor: { copy.edgeColors[$0] })]
            let gs = [g.weisfeilerLehmanSubgraphHashes(iterations: iterations), g.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { dv[$0]! }), g.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { dv[$0]! }, edgeColor: { d.edgeColors[$0] })]
            let hs = [h.weisfeilerLehmanSubgraphHashes(iterations: iterations), h.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { cv[$0]! }), h.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { cv[$0]! }, edgeColor: { copy.edgeColors[$0] })]
            ar = gs.map { s in d.labels.map { Array(s.hashes(of: $0)) } }
            br = hs.map { s in d.labels.indices.map { Array(s.hashes(of: copy.labels[perm[$0]])) } }
        } else {
            let g = undirected(d), h = undirected(copy)
            a = [g.weisfeilerLehmanGraphHash(iterations: iterations), g.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { dv[$0]! }), g.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { dv[$0]! }, edgeColor: { d.edgeColors[$0] })]
            b = [h.weisfeilerLehmanGraphHash(iterations: iterations), h.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { cv[$0]! }), h.weisfeilerLehmanGraphHash(iterations: iterations, vertexColor: { cv[$0]! }, edgeColor: { copy.edgeColors[$0] })]
            let gs = [g.weisfeilerLehmanSubgraphHashes(iterations: iterations), g.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { dv[$0]! }), g.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { dv[$0]! }, edgeColor: { d.edgeColors[$0] })]
            let hs = [h.weisfeilerLehmanSubgraphHashes(iterations: iterations), h.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { cv[$0]! }), h.weisfeilerLehmanSubgraphHashes(iterations: iterations, vertexColor: { cv[$0]! }, edgeColor: { copy.edgeColors[$0] })]
            ar = gs.map { s in d.labels.map { Array(s.hashes(of: $0)) } }
            br = hs.map { s in d.labels.indices.map { Array(s.hashes(of: copy.labels[perm[$0]])) } }
        }
        check(a == b, "WL graph hashes of a relabelled copy differ (directed \(isDirected), iterations \(iterations))")
        check(ar == br, "WL subgraph hashes of a relabelled copy differ (directed \(isDirected), iterations \(iterations))")
        for r in ar { check(r.allSatisfy { $0.count == iterations }, "WL subgraph hashes: not one per round") }
    }

    /// The automorphism group and canonical labeling against brute force: the order is the
    /// number of automorphisms (with the same colours), two vertices share an orbit exactly when an
    /// automorphism maps one to the other, and the canonical labeling is a permutation.
    static func checkGroup(_ d: Drawn, directed isDirected: Bool, colors: Int) {
        let n = d.labels.count
        let dv = Dictionary(uniqueKeysWithValues: zip(d.labels, d.vertexColors))
        let colored = colors > 0
        let autos = bruteForce(d, d, .isomorphism, directed: isDirected, colored: colored)
        let order: Double, orbit: [Int], permutation: [Int]
        if isDirected {
            let g = directed(d)
            let group = colors == 0 ? g.automorphismGroup() : colors == 1 ? g.automorphismGroup(vertexColor: { dv[$0]! }) : g.automorphismGroup(vertexColor: { dv[$0]! }, edgeColor: { d.edgeColors[$0] })
            order = group.order
            orbit = d.labels.map { group.orbit(of: $0) }
            for gamma in group.generators { check(autos.contains(positions(gamma.images, d)), "a generator is not an automorphism") }
            permutation = d.labels.map { g.canonicalLabeling().canonicalIndex(of: $0) }
        } else {
            let g = undirected(d)
            let group = colors == 0 ? g.automorphismGroup() : colors == 1 ? g.automorphismGroup(vertexColor: { dv[$0]! }) : g.automorphismGroup(vertexColor: { dv[$0]! }, edgeColor: { d.edgeColors[$0] })
            order = group.order
            orbit = d.labels.map { group.orbit(of: $0) }
            for gamma in group.generators { check(autos.contains(positions(gamma.images, d)), "a generator is not an automorphism") }
            permutation = d.labels.map { g.canonicalLabeling().canonicalIndex(of: $0) }
        }
        check(order == Double(autos.count), "group order \(order), expected \(autos.count)")
        for u in 0 ..< n {
            for v in 0 ..< n {
                let same = autos.contains { $0[u] == v }
                check((orbit[u] == orbit[v]) == same, "orbits of \(u) and \(v): \(orbit[u] == orbit[v]), expected \(same)")
            }
        }
        check(permutation.sorted() == Array(0 ..< n), "the canonical labeling is not a permutation")
    }

    /// Canonical forms are equal exactly when the graphs are isomorphic (without colours).
    static func checkForms(_ p: Drawn, _ t: Drawn, directed isDirected: Bool) {
        let isomorphic = !bruteForce(p, t, .isomorphism, directed: isDirected, colored: false).isEmpty
        let equal = isDirected ? directed(p).canonicalLabeling().form == directed(t).canonicalLabeling().form : undirected(p).canonicalLabeling().form == undirected(t).canonicalLabeling().form
        check(equal == isomorphic, "canonical forms equal \(equal), isomorphic \(isomorphic)")
    }

    static func fuzz(_ input: inout FuzzInput) {
        let isDirected = input.int(below: 2) == 1
        // 0: no colours; 1: vertex colours; 2: vertex and edge colours.
        let colors = input.int(below: 3)
        let vertexKinds = colors == 0 ? 1 : 1 + input.int(below: 3)
        let edgeKinds = colors == 2 ? 1 + input.int(below: 3) : 1
        switch input.int(below: 3) {
        case 0:
            // A relabelled copy: always isomorphic, with equal hashes.
            let n = input.int(in: 0 ... 6)
            let d = draw(&input, vertices: n, maxEdges: 10, vertexKinds: vertexKinds, edgeKinds: edgeKinds, labelBase: 0)
            let (copy, perm) = relabel(&input, d, directed: isDirected)
            let truth = Array(0 ..< n).map { perm[$0] }
            if isDirected {
                checkDirected(d, copy, colors: colors)
                let g = directed(d), h = directed(copy)
                check(g.isIsomorphic(to: h), "a relabelled copy is not isomorphic")
                if colors == 2 {
                    let dv = Dictionary(uniqueKeysWithValues: zip(d.labels, d.vertexColors)), cv = Dictionary(uniqueKeysWithValues: zip(copy.labels, copy.vertexColors))
                    let all = g.isomorphisms(to: h, vertexColor: { dv[$0]! }, otherVertexColor: { cv[$0]! }, edgeColor: { d.edgeColors[$0] }, otherEdgeColor: { copy.edgeColors[$0] }).map { positions($0.images, copy) }
                    check(all.contains(truth), "the relabelling itself is not among the coloured isomorphisms")
                }
            } else {
                checkUndirected(d, copy, colors: colors)
                let g = undirected(d), h = undirected(copy)
                check(g.isIsomorphic(to: h), "a relabelled copy is not isomorphic")
                if colors == 2 {
                    let dv = Dictionary(uniqueKeysWithValues: zip(d.labels, d.vertexColors)), cv = Dictionary(uniqueKeysWithValues: zip(copy.labels, copy.vertexColors))
                    let all = g.isomorphisms(to: h, vertexColor: { dv[$0]! }, otherVertexColor: { cv[$0]! }, edgeColor: { d.edgeColors[$0] }, otherEdgeColor: { copy.edgeColors[$0] }).map { positions($0.images, copy) }
                    check(all.contains(truth), "the relabelling itself is not among the coloured isomorphisms")
                }
            }
            checkHashes(d, copy, perm, directed: isDirected, iterations: input.int(in: 0 ... 4))
            checkGroup(d, directed: isDirected, colors: colors)
            checkForms(d, copy, directed: isDirected)
        case 1:
            // Two graphs of one size.
            let n = input.int(in: 0 ... 6)
            let p = draw(&input, vertices: n, maxEdges: 9, vertexKinds: vertexKinds, edgeKinds: edgeKinds, labelBase: 0)
            let t = draw(&input, vertices: n, maxEdges: 9, vertexKinds: vertexKinds, edgeKinds: edgeKinds, labelBase: 500)
            if isDirected { checkDirected(p, t, colors: colors) } else { checkUndirected(p, t, colors: colors) }
            checkForms(p, t, directed: isDirected)
        default:
            // A pattern and a larger target.
            let nt = input.int(in: 0 ... 7)
            let np = input.int(in: 0 ... min(nt, 4))
            let p = draw(&input, vertices: np, maxEdges: 6, vertexKinds: vertexKinds, edgeKinds: edgeKinds, labelBase: 0)
            let t = draw(&input, vertices: nt, maxEdges: 14, vertexKinds: vertexKinds, edgeKinds: edgeKinds, labelBase: 500)
            if isDirected { checkDirected(p, t, colors: colors) } else { checkUndirected(p, t, colors: colors) }
        }
    }
}
