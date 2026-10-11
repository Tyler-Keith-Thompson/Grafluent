// Induced subgraph isomorphism (catalog IS-087 – IS-116): the receiver is the pattern; every pair
// of pattern vertices has the multiplicity of its image pair, an empty pattern has one mapping.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Subgraph isomorphism (induced)")
struct SubgraphIsomorphismTests {
    @Test("IS-087 P3 in K3: every image has the third edge")
    func is087() {
        // `U: P(0,1,2)` → `U: K(3)`; `isSubgraphIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-088 K2 in P4: each edge, both ways")
    func is088() {
        // `U: P(0,1)` → `U: P(0,1,2,3)`; `subgraphIsomorphisms(to:)` ⇒ {[0, 1], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0], [1, 2], [2, 1], [2, 3], [3, 2]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 6)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 6)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-089 two isolated vertices in P4: non-adjacent pairs")
    func is089() {
        // `U: E(2)` → `U: P(0,1,2,3)`; `subgraphIsomorphisms(to:)` ⇒ {[0, 2], [0, 3], [1, 3], [2, 0], [3, 0], [3, 1]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 2], [0, 3], [1, 3], [2, 0], [3, 0], [3, 1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 6)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 6)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-090 C4 in K4: never induced")
    func is090() {
        // `U: C(0,1,2,3)` → `U: K(4)`; `subgraphIsomorphisms(to:).count` ⇒ #0
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        #expect(pattern.isSubgraphIsomorphic(to: target) == false)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-091 2K2 in P4: the middle edge is in the way")
    func is091() {
        // `U: 0-1, 2-3` → `U: P(0,1,2,3)`; `subgraphIsomorphisms(to:).count` ⇒ #0
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        #expect(pattern.isSubgraphIsomorphic(to: target) == false)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-092 K3 in Petersen (girth 5)")
    func is092() {
        // `U: K(3)` → `U: nx(petersen)`; `isSubgraphIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-093 C5 in Petersen: 12 five-cycles, 10 ways each")
    func is093() {
        // `U: C(0,1,2,3,4)` → `U: nx(petersen)`; `subgraphIsomorphisms(to:).count` ⇒ #120
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 120)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-094 P3 in Petersen")
    func is094() {
        // `U: P(0,1,2)` → `U: nx(petersen)`; `subgraphIsomorphisms(to:).count` ⇒ #60
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 60)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 60)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 60)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-095 C6 in Petersen")
    func is095() {
        // `U: C(0,1,2,3,4,5)` → `U: nx(petersen)`; `subgraphIsomorphisms(to:).count` ⇒ #120
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 120)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-096 K4 in K6")
    func is096() {
        // `U: K(4)` → `U: K(6)`; `subgraphIsomorphisms(to:).count` ⇒ #360
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5],
            [3, 4], [3, 5], [4, 5]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 360)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 360)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 360)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-097 C4 in Q3: the six faces")
    func is097() {
        // `U: C(0,1,2,3)` → `U: Q(3)`; `subgraphIsomorphisms(to:).count` ⇒ #48
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 48)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 48)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 48)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-098 P4 in grid 3x3")
    func is098() {
        // `U: P(0,1,2,3)` → `U: grid(3,3)`; `subgraphIsomorphisms(to:).count` ⇒ #48
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [3, 6], [4, 5], [4, 7], [5, 8], [6, 7], [7, 8]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 9), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 48)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 48)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 48)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-099 claw K1,3 in grid 4x4")
    func is099() {
        // `U: S(0;1..3)` → `U: grid(4,4)`; `subgraphIsomorphisms(to:).count` ⇒ #144
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [1, 2], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 8], [5, 6], [5, 9], [6, 7],
            [6, 10], [7, 11], [8, 9], [8, 12], [9, 10], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [13, 14], [14, 15]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 144)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 144)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 144)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-100 pattern larger than target")
    func is100() {
        // `U: K(3)` → `U: K(2)`; `isSubgraphIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-101 empty pattern: the empty mapping")
    func is101() {
        // `U:` → `U: P(0,1,2)`; `subgraphIsomorphisms(to:)` ⇒ {[]}
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 1)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-102 empty pattern, empty target")
    func is102() {
        // `U:` → `U:`; `subgraphIsomorphisms(to:).count` ⇒ #1
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>()
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 1)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-103 a whole graph is its own induced subgraph")
    func is103() {
        // `U: nx(petersen)` → `U: nx(petersen)`; `subgraphIsomorphisms(to:).count` ⇒ #120
        let patternEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 120)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-104 K1 into a vertex with a loop: the loop is induced")
    func is104() {
        // `U: [0]` → `U: 0-0, 0-1`; `subgraphIsomorphisms(to:)` ⇒ {[1]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 1)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-105 loop pattern into a loop target")
    func is105() {
        // `U: 0-0` → `U: 0-0, 0-1`; `subgraphIsomorphisms(to:)` ⇒ {[0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 1)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-106 K2 into a parallel pair: multiplicity must be equal")
    func is106() {
        // `U: 0-1` → `U: 0=1`; `isSubgraphIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-107 parallel pair into a parallel pair")
    func is107() {
        // `U: 0=1` → `U: 0=1, 1-2`; `subgraphIsomorphisms(to:)` ⇒ {[0, 1], [1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 2)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-108 directed: arc into a 2-cycle")
    func is108() {
        // `D: 0>1` → `D: 0>1, 1>0`; `isSubgraphIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        // The catalog's value.
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-109 directed: out-path in directed C3")
    func is109() {
        // `D: 0>1, 1>2` → `D: C(0,1,2)`; `isSubgraphIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        // The catalog's value.
        #expect(!pattern.isSubgraphIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-110 directed: out-path in directed C4")
    func is110() {
        // `D: 0>1, 1>2` → `D: C(0,1,2,3)`; `subgraphIsomorphisms(to:).count` ⇒ #4
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 4)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 4)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 4)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-111 directed: arc in the transitive tournament on 4")
    func is111() {
        // `D: 0>1` → `D: tt(4)`; `subgraphIsomorphisms(to:).count` ⇒ #6
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)])
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 6)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 6)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 6)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-112 coloured: red–blue edges in a coloured path")
    func is112() {
        // `U: P(0,1)` → `U: P(0,1,2,3)`; `subgraphIsomorphisms(to:) vertexColor: G [r,b] H [r,b,b,r]` ⇒ {[0, 1], [3, 2]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let patternColor: [Int: String] = [0: "r", 1: "b"]
        let targetColor: [Int: String] = [0: "r", 1: "b", 2: "b", 3: "r"]
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [3, 2]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included, with equal vertex colours.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 2)
        #expect(pattern.isSubgraphIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.subgraphIsomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-113 coloured edges: an a-edge in C4")
    func is113() {
        // `U: P(0,1)` → `U: C(0,1,2,3)`; `subgraphIsomorphisms(to:) edgeColor: G [a] H [a,b,a,b]` ⇒ {[0, 1], [1, 0], [2, 3], [3, 2]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["a"]
        let targetEdgeColor = ["a", "b", "a", "b"]
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0], [2, 3], [3, 2]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 4)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 4)
        #expect(pattern.isSubgraphIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.subgraphIsomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-114 subgraphIsomorphism(to:): the unique one")
    func is114() throws {
        // `U: P(0,1,2)` → `U: [9] P(5,6,7), 9-5`; `subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]` ⇒ [9, 5, 6]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: [9, 5, 6, 7], edges: [UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(9, 5)])
        let patternColor: [Int: String] = [0: "x", 1: "y", 2: "z"]
        let targetColor: [Int: String] = [9: "x", 5: "y", 6: "z", 7: "w"]
        // The catalog's value.
        let mapping = try #require(pattern.subgraphIsomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
        #expect(Array(mapping.images) == [9, 5, 6])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [9, 5, 6])
        #expect(pattern.vertices.map { mapping.image(safe: $0) } == [9, 5, 6])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0, 1, 2, nil])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included, with equal vertex colours.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 1)
        #expect(pattern.isSubgraphIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.subgraphIsomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-115 subgraphIsomorphism(to:): none")
    func is115() {
        // `U: K(3)` → `U: nx(petersen)`; `subgraphIsomorphism(to:)` ⇒ nil
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(pattern.subgraphIsomorphism(to: target) == nil)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 0)
        #expect(pattern.isSubgraphIsomorphic(to: target) == false)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-116 random target lcg(14,30,5): P4")
    func is116() {
        // `U: P(0,1,2,3)` → `U: lcg(14,30,5)`; `subgraphIsomorphisms(to:).count` ⇒ #70
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let targetEdges: [[Int]] = [
            [0, 11], [4, 1], [3, 5], [12, 2], [1, 4], [8, 7], [5, 3], [8, 13], [12, 8], [6, 8], [13, 8], [13, 2],
            [1, 11], [10, 5], [3, 5], [9, 1], [0, 1], [12, 4], [2, 6], [6, 0], [6, 4], [2, 8], [3, 6], [4, 6],
            [13, 10], [9, 5], [4, 8], [3, 8], [0, 12], [9, 13]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 14), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.subgraphIsomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 70)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
                    return a == b
                }
            }
        }
        #expect(all.count == 70)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.subgraphIsomorphisms(to: target)).count == 70)
        #expect(pattern.isSubgraphIsomorphic(to: target) == true)
        let first = pattern.subgraphIsomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.subgraphIsomorphism(to: target).map { Array($0.images) } == first)
    }
}
