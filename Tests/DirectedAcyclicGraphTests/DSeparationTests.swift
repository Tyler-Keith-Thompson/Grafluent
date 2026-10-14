// d-separation, minimal d-separators (van der Zander and Liśkiewicz) and the moral graph.
// Hand-computed chains, forks, colliders and the diamond; the restrictions of minimal
// separators; the checked spellings and exits; and a property test against every trail of small
// DAGs, with minimality and existence checked over every vertex subset.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing

@Suite("d-separation and the moral graph")
struct DSeparationTests {
    @Test("A chain, a fork and a collider: the middle vertex blocks the first two and opens the third, as does a descendant of the collider")
    func threeShapes() throws {
        let chain = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(chain.isDSeparator([1], between: [0], and: [2]))
        #expect(!chain.isDSeparator([], between: [0], and: [2]))
        let fork = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)]))
        #expect(fork.isDSeparator([0], between: [1], and: [2]))
        #expect(!fork.isDSeparator([], between: [1], and: [2]))
        let collider = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]))
        #expect(collider.isDSeparator([], between: [0], and: [1]))
        #expect(!collider.isDSeparator([2], between: [0], and: [1]))
        #expect(!collider.isDSeparator([3], between: [0], and: [1]))
        // Empty sets are separated by anything.
        #expect(collider.isDSeparator([2], between: [], and: [1]))
        #expect(collider.isDSeparator([], between: [0], and: []))
    }

    @Test("The diamond 0 → 1, 2 → 3: both middle vertices are needed; sets on either side")
    func diamond() throws {
        let edges = [(0, 1), (0, 2), (1, 3), (2, 3)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let dag = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 5, edges: edges))
        #expect(!dag.isDSeparator([1], between: [0], and: [3]))
        #expect(dag.isDSeparator([1, 2], between: [0], and: [3]))
        #expect(!dag.isDSeparator([0, 3], between: [1], and: [2]))
        #expect(dag.isDSeparator([0], between: [1], and: [2]))
        #expect(dag.isDSeparator([], between: [0, 1], and: [4]))
        #expect(dag.minimalDSeparator(between: [0], and: [3]) == [1, 2])
        #expect(dag.minimalDSeparator(between: [1], and: [2]) == [0])
        #expect(dag.minimalDSeparator(between: [0], and: [4]) == [])
    }

    @Test("Minimal separators: the chain's middle, none when the restriction leaves it out, none when an included descendant opens the collider, included vertices kept")
    func minimalRestrictions() throws {
        let chain = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(chain.minimalDSeparator(between: [0], and: [2]) == [1])
        #expect(chain.minimalDSeparator(between: [0], and: [2], restrictedTo: []) == nil)
        #expect(chain.minimalDSeparator(between: [0], and: [2], restrictedTo: [1]) == [1])
        #expect(chain.minimalDSeparator(between: [0], and: [2], including: [1], restrictedTo: [1]) == [1])
        let collider = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]))
        #expect(collider.minimalDSeparator(between: [0], and: [1]) == [])
        #expect(collider.minimalDSeparator(between: [0], and: [1], including: [3]) == nil)
        // An adjacent pair is never separated.
        #expect(collider.minimalDSeparator(between: [0], and: [2]) == nil)
        // An included vertex stays, even below the pair.
        let tail = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)]))
        #expect(tail.minimalDSeparator(between: [0], and: [2], including: [3]) == [1, 3])
        #expect(tail.minimalDSeparator(between: [1], and: [3]) == [2])
    }

    @Test("Other bases: String vertices on a DirectedPseudograph with parallel edges (answers in vertices order), and a StableDirectedGraph")
    func otherBases() throws {
        let edges = [("a", "b"), ("a", "b"), ("c", "b"), ("b", "d")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let dag = try #require(DirectedAcyclicGraph<DirectedPseudograph<String>>(vertices: ["d", "c", "b", "a"], edges: edges))
        #expect(dag.isDSeparator([], between: ["a"], and: ["c"]))
        #expect(!dag.isDSeparator(["d"], between: ["a"], and: ["c"]))
        #expect(dag.minimalDSeparator(between: ["a"], and: ["d"]) == ["b"])
        #expect(dag.minimalDSeparator(between: ["a", "c"], and: ["d"]) == ["b"])
        let stable = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 0), DirectedEdge(from: 0, to: 1)]))
        #expect(stable.minimalDSeparator(between: [3], and: [1]) == [0, 2])
        #expect(stable.isDSeparator([0, 2], between: [3], and: [1]))
    }

    @Test("The checked spellings throw VertexNotFound for a non-vertex in any argument")
    func checked() throws {
        let dag = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]))
        #expect(throws: VertexNotFound.self) { try dag.isDSeparator(checked: [9], between: [0], and: [2]) }
        #expect(throws: VertexNotFound.self) { try dag.isDSeparator(checked: [1], between: [9], and: [2]) }
        #expect(throws: VertexNotFound.self) { try dag.isDSeparator(checked: [1], between: [0], and: [9]) }
        #expect(try dag.isDSeparator(checked: [1], between: [0], and: [2]))
        #expect(throws: VertexNotFound.self) { try dag.minimalDSeparator(checkedBetween: [9], and: [2]) }
        #expect(throws: VertexNotFound.self) { try dag.minimalDSeparator(checkedBetween: [0], and: [9]) }
        #expect(throws: VertexNotFound.self) { try dag.minimalDSeparator(checkedBetween: [0], and: [2], including: [9]) }
        #expect(throws: VertexNotFound.self) { try dag.minimalDSeparator(checkedBetween: [0], and: [2], restrictedTo: [9]) }
        #expect(try dag.minimalDSeparator(checkedBetween: [0], and: [2]) == [1])
    }

    @Test("Traps: a non-vertex, overlapping sets, an included vertex outside the restriction")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3)
            _ = dag.isDSeparator([7], between: [0], and: [1])
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3)
            _ = dag.isDSeparator([0], between: [0], and: [1])
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3)
            _ = dag.isDSeparator([2], between: [0], and: [0])
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3)
            _ = dag.minimalDSeparator(between: [0], and: [1], including: [1])
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3)
            _ = dag.minimalDSeparator(between: [0], and: [1], including: [2], restrictedTo: [])
        }
        await #expect(processExitsWith: .failure) {
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 3)
            _ = dag.minimalDSeparator(between: [0], and: [1], restrictedTo: [5])
        }
    }

    @Test("The moral graph: edges without directions, and the parents of each vertex married once")
    func moralGraph() throws {
        let edges = [(0, 2), (1, 2), (2, 3), (0, 3), (0, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let dag = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 5, edges: edges))
        let moral = UndirectedAdjacencyList<Int>.moralGraph(of: dag)
        #expect(Array(moral.vertices) == [0, 1, 2, 3, 4])
        #expect(Set(moral.edges) == Set([(0, 1), (0, 2), (0, 3), (1, 2), (2, 3)].map { UndirectedEdge($0.0, $0.1) }))
        #expect(moral.edgeCount == 5)
        let named = try #require(DirectedAcyclicGraph<DirectedPseudograph<String>>(vertices: ["z", "y", "x"], edges: [DirectedEdge(from: "x", to: "z"), DirectedEdge(from: "x", to: "z"), DirectedEdge(from: "y", to: "z")]))
        let married = UndirectedAdjacencyList<Int>.moralGraph(of: named)
        #expect(Set(married.edges) == [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        #expect(UndirectedAdjacencyList<Int>.moralGraph(of: DirectedAcyclicGraph<AdjacencyList<Int>>()).vertexCount == 0)
    }

    @Test("d-separation against every trail; minimal separators separate, are minimal, and exist exactly when some allowed set separates", .tags(.randomized))
    func againstTrails() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: Gen.int(in: 2 ... 6), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            var arcs = Set<[Int]>()
            for (a, b) in raw where a % n != b % n { arcs.insert([min(a % n, b % n), max(a % n, b % n)]) }
            let sorted = arcs.sorted { $0.lexicographicallyPrecedes($1) }
            guard let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< n, edges: sorted.map { DirectedEdge(from: $0[0], to: $0[1]) }) else { return }
            var descendants = [Int](repeating: 0, count: n)
            for v in (0 ..< n).reversed() {
                descendants[v] = 1 << v
                for arc in sorted where arc[0] == v { descendants[v] |= descendants[arc[1]] }
            }
            let adjacent = (0 ..< n).map { v in sorted.filter { $0.contains(v) }.map { $0[0] == v ? $0[1] : $0[0] } }
            // Whether some active trail joins u and v given z, by every simple trail.
            func connected(_ u: Int, _ v: Int, _ z: Int) -> Bool {
                var found = false
                func walk(_ trail: [Int]) {
                    if found { return }
                    let last = trail[trail.count - 1]
                    if last == v {
                        var active = true
                        for i in 1 ..< trail.count - 1 {
                            let a = trail[i - 1], m = trail[i], b = trail[i + 1]
                            let collider = arcs.contains([a, m]) && a < m && arcs.contains([b, m]) && b < m
                            if collider ? descendants[m] & z == 0 : z & (1 << m) != 0 { active = false }
                        }
                        if active { found = true }
                        return
                    }
                    for w in adjacent[last] where !trail.contains(w) { walk(trail + [w]) }
                }
                walk([u])
                return found
            }
            let x = seed % n, y = (x + 1 + (seed / n) % (n - 1)) % n
            let others = (0 ..< n).filter { $0 != x && $0 != y }
            func separates(_ z: Int) -> Bool { !connected(x, y, z) }
            let mask = others.reduce(0) { (seed >> ($1 + 3)) & 1 == 1 ? $0 | (1 << $1) : $0 }
            let z = (0 ..< n).filter { mask & (1 << $0) != 0 }
            #expect(dag.isDSeparator(z, between: [x], and: [y]) == separates(mask), "\(sorted) \(x) \(y) \(z)")
            // Minimal separators with an included set and a restriction drawn from the seed.
            let restrictedMask = (seed >> 9) & 1 == 1 ? others.reduce(0) { (seed >> ($1 + 11)) & 1 == 1 ? $0 | (1 << $1) : $0 } : others.reduce(0) { $0 | (1 << $1) }
            let includedMask = (seed >> 10) & 1 == 1 ? restrictedMask & mask : 0
            let restricted = (seed >> 9) & 1 == 1 ? (0 ..< n).filter { restrictedMask & (1 << $0) != 0 } : nil
            let included = (0 ..< n).filter { includedMask & (1 << $0) != 0 }
            let exists = (0 ..< 1 << n).contains { s in s & ~restrictedMask == 0 && s & includedMask == includedMask && separates(s) }
            let found = dag.minimalDSeparator(between: [x], and: [y], including: included, restrictedTo: restricted)
            #expect((found != nil) == exists, "\(sorted) \(x) \(y) including \(included) restricted \(String(describing: restricted))")
            if let found {
                let s = found.reduce(0) { $0 | (1 << $1) }
                #expect(found == found.sorted() && s & ~restrictedMask == 0 && s & includedMask == includedMask)
                #expect(separates(s))
                for sub in 0 ..< 1 << n where sub & s == sub && sub != s && sub & includedMask == includedMask {
                    #expect(!separates(sub), "\(found) has the smaller separator \(sub)")
                }
            }
        }
    }
}
