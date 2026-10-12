// Monomorphism (catalog IS-117 – IS-146): every pattern multiset is contained in its image pair's;
// Hamiltonian cycles and paths, perfect matchings and cycles counted as pattern embeddings.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Monomorphism (non-induced)")
struct MonomorphismTests {
    @Test("IS-117 P3 in K3")
    func is117() {
        // `U: P(0,1,2)` → `U: K(3)`; `monomorphisms(to:)` ⇒ {[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 6)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 6)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-118 two isolated vertices in P4: every ordered pair")
    func is118() {
        // `U: E(2)` → `U: P(0,1,2,3)`; `monomorphisms(to:).count` ⇒ #12
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 12)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 12)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 12)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-119 C4 in K4: three 4-cycles, 8 ways each")
    func is119() {
        // `U: C(0,1,2,3)` → `U: K(4)`; `monomorphisms(to:).count` ⇒ #24
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 24)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 24)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 24)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-120 2K2 in P4")
    func is120() {
        // `U: 0-1, 2-3` → `U: P(0,1,2,3)`; `monomorphisms(to:)` ⇒ {[0, 1, 2, 3], [0, 1, 3, 2], [1, 0, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [2, 3, 1, 0], [3, 2, 0, 1], [3, 2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1, 2, 3], [0, 1, 3, 2], [1, 0, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [2, 3, 1, 0], [3, 2, 0, 1], [3, 2, 1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 8)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 8)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-121 C5 in Petersen: same as induced (girth 5)")
    func is121() {
        // `U: C(0,1,2,3,4)` → `U: nx(petersen)`; `monomorphisms(to:).count` ⇒ #120
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 120)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-122 C4 in K3,3")
    func is122() {
        // `U: C(0,1,2,3)` → `U: KB(0..2;3..5)`; `monomorphisms(to:).count` ⇒ #72
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let targetEdges: [[Int]] = [
            [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]
        ]
        let target = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 72)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 72)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 72)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-123 Hamiltonian cycles: C8 in Q3")
    func is123() {
        // `U: C(0,1,2,3,4,5,6,7)` → `U: Q(3)`; `monomorphisms(to:).count` ⇒ #96
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(7, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 96)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 96)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 96)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-124 Hamiltonian paths: P10 in Petersen")
    func is124() {
        // `U: P(0,1,2,3,4,5,6,7,8,9)` → `U: nx(petersen)`; `monomorphisms(to:).count` ⇒ #240
        let patternEdges: [[Int]] = [
            [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 240)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 240)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 240)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-125 spanning: C10 in Petersen (not Hamiltonian)")
    func is125() {
        // `U: C(0,1,2,3,4,5,6,7,8,9)` → `U: nx(petersen)`; `isMonomorphic(to:)` ⇒ false
        let patternEdges: [[Int]] = [
            [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [9, 0]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-126 perfect matchings: 3K2 in K3,3")
    func is126() {
        // `U: 0-1, 2-3, 4-5` → `U: KB(0..2;3..5)`; `monomorphisms(to:).count` ⇒ #288
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(4, 5)])
        let targetEdges: [[Int]] = [
            [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]
        ]
        let target = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 288)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 288)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 288)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-127 K4 in K6")
    func is127() {
        // `U: K(4)` → `U: K(6)`; `monomorphisms(to:).count` ⇒ #360
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5],
            [3, 4], [3, 5], [4, 5]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 360)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 360)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 360)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-128 K4 in grid")
    func is128() {
        // `U: K(4)` → `U: grid(3,3)`; `isMonomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [3, 6], [4, 5], [4, 7], [5, 8], [6, 7], [7, 8]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 9), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-129 empty pattern")
    func is129() {
        // `U:` → `U: K(3)`; `monomorphisms(to:)` ⇒ {[]}
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 1)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-130 pattern larger than target")
    func is130() {
        // `U: E(3)` → `U: K(2)`; `isMonomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-131 K1 into a loop vertex: allowed")
    func is131() {
        // `U: [0]` → `U: [0] 0-0`; `monomorphisms(to:)` ⇒ {[0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 1)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-132 loop pattern into a vertex without a loop")
    func is132() {
        // `U: 0-0` → `U: 0-1`; `isMonomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-133 K2 into a parallel pair: one copy is enough")
    func is133() {
        // `U: 0-1` → `U: 0=1`; `monomorphisms(to:)` ⇒ {[0, 1], [1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 2)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-134 parallel pair into a single edge")
    func is134() {
        // `U: 0=1` → `U: 0-1`; `isMonomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-135 triple edge into a double edge")
    func is135() {
        // `U: 0=1, 0-1` → `U: 0=1`; `isMonomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-136 double edge into a triple edge")
    func is136() {
        // `U: 0=1` → `U: 0=1, 0-1`; `monomorphisms(to:)` ⇒ {[0, 1], [1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 2)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-137 directed: arc into a 2-cycle")
    func is137() {
        // `D: 0>1` → `D: 0>1, 1>0`; `monomorphisms(to:)` ⇒ {[0, 1], [1, 0]}
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 2)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-138 directed: out-path in directed C3")
    func is138() {
        // `D: 0>1, 1>2` → `D: C(0,1,2)`; `monomorphisms(to:)` ⇒ {[0, 1, 2], [1, 2, 0], [2, 0, 1]}
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1, 2], [1, 2, 0], [2, 0, 1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 3)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 3)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-139 directed: 2-cycle into the transitive tournament")
    func is139() {
        // `D: 0>1, 1>0` → `D: tt(4)`; `isMonomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-140 directed: directed triangles in tpaley(7)")
    func is140() {
        // `D: C(0,1,2)` → `D: tpaley(7)`; `monomorphisms(to:).count` ⇒ #42
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [2, 6], [3, 0], [3, 4], [3, 5],
            [4, 1], [4, 5], [4, 6], [5, 0], [5, 2], [5, 6], [6, 0], [6, 1], [6, 3]
        ]
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 7), edges: targetEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 42)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 42)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 42)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-141 coloured edges: multiset containment")
    func is141() {
        // `U: 0=1` → `U: 0=1, 0-1`; `monomorphisms(to:) edgeColor: G [a,b] H [a,a,b]` ⇒ {[0, 1], [1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let patternEdgeColor = ["a", "b"]
        let targetEdgeColor = ["a", "a", "b"]
        // The catalog's value.
        let all = pattern.monomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: [String]] = [:]
        for (position, edge) in pattern.edges.enumerated() {
            patternPairs[[edge.u, edge.v], default: []].append(patternEdgeColor[position])
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: []].append(patternEdgeColor[position]) }
        }
        var targetPairs: [[Int]: [String]] = [:]
        for (position, edge) in target.edges.enumerated() {
            targetPairs[[edge.u, edge.v], default: []].append(targetEdgeColor[position])
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: []].append(targetEdgeColor[position]) }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a.allSatisfy { c in a.filter { $0 == c }.count <= b.filter { $0 == c }.count }
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 2)
        #expect(pattern.isMonomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.monomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-142 coloured edges: a colour missing")
    func is142() {
        // `U: 0=1` → `U: 0=1, 0-1`; `isMonomorphic(to:) edgeColor: G [a,b] H [a,a,c]` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let patternEdgeColor = ["a", "b"]
        let targetEdgeColor = ["a", "a", "c"]
        // The catalog's value.
        #expect(!pattern.isMonomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: [String]] = [:]
        for (position, edge) in pattern.edges.enumerated() {
            patternPairs[[edge.u, edge.v], default: []].append(patternEdgeColor[position])
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: []].append(patternEdgeColor[position]) }
        }
        var targetPairs: [[Int]: [String]] = [:]
        for (position, edge) in target.edges.enumerated() {
            targetPairs[[edge.u, edge.v], default: []].append(targetEdgeColor[position])
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: []].append(targetEdgeColor[position]) }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a.allSatisfy { c in a.filter { $0 == c }.count <= b.filter { $0 == c }.count }
                }
            }
        }
        let all = pattern.monomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 0)
        let first = pattern.monomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-143 coloured vertices")
    func is143() {
        // `U: P(0,1)` → `U: K(3)`; `monomorphisms(to:) vertexColor: G [r,r] H [r,b,r]` ⇒ {[0, 2], [2, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let patternColor: [Int: String] = [0: "r", 1: "r"]
        let targetColor: [Int: String] = [0: "r", 1: "b", 2: "r"]
        // The catalog's value.
        let all = pattern.monomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(Set(all) == [[0, 2], [2, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset, with equal vertex colours.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            guard pattern.vertices.allSatisfy({ patternColor[$0] == targetColor[image[$0]!] }) else { return false }
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 2)
        #expect(pattern.isMonomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.monomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-144 monomorphism(to:): none")
    func is144() {
        // `U: C(0,1,2,3)` → `U: nx(petersen)`; `monomorphism(to:)` ⇒ nil
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(pattern.monomorphism(to: target) == nil)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 0)
        #expect(pattern.isMonomorphic(to: target) == false)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-145 monomorphism(to:): the unique one")
    func is145() throws {
        // `U: P(0,1,2)` → `U: K(3)`; `monomorphism(to:) vertexColor: G [a,b,c] H [c,a,b]` ⇒ [1, 2, 0]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let patternColor: [Int: String] = [0: "a", 1: "b", 2: "c"]
        let targetColor: [Int: String] = [0: "c", 1: "a", 2: "b"]
        // The catalog's value.
        let mapping = try #require(pattern.monomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
        #expect(Array(mapping.images) == [1, 2, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 2, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [1, 2, 0])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [2, 0, 1])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset, with equal vertex colours.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            guard pattern.vertices.allSatisfy({ patternColor[$0] == targetColor[image[$0]!] }) else { return false }
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        let all = pattern.monomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 1)
        #expect(pattern.isMonomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.monomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-146 random target lcg(14,30,5): C4")
    func is146() {
        // `U: C(0,1,2,3)` → `U: lcg(14,30,5)`; `monomorphisms(to:).count` ⇒ #120
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let targetEdges: [[Int]] = [
            [0, 11], [4, 1], [3, 5], [12, 2], [1, 4], [8, 7], [5, 3], [8, 13], [12, 8], [6, 8], [13, 8], [13, 2],
            [1, 11], [10, 5], [3, 5], [9, 1], [0, 1], [12, 4], [2, 6], [6, 0], [6, 4], [2, 8], [3, 6], [4, 6],
            [13, 10], [9, 5], [4, 8], [3, 8], [0, 12], [9, 13]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 14), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.monomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { patternPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.u, edge.v], default: 0] += 1
            if edge.u != edge.v { targetPairs[[edge.v, edge.u], default: 0] += 1 }
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a <= b
                }
            }
        }
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.monomorphisms(to: target)).count == 120)
        #expect(pattern.isMonomorphic(to: target) == true)
        let first = pattern.monomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.monomorphism(to: target).map { Array($0.images) } == first)
    }
}
