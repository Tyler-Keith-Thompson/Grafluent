// Directed graphs (catalog IS-057 – IS-070): arc direction is kept, so a 2-cycle is not two parallel
// arcs; tournaments, directed loops, a directed multigraph.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Directed isomorphism")
struct IsomorphismDirectedTests {
    @Test("IS-057 out-path against in-star: same counts")
    func is057() {
        // `D: 0>1, 1>2` → `D: 0>1, 2>1`; `isIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 0)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-058 directed C3 against itself")
    func is058() {
        // `D: C(0,1,2)` → `D: C(0,1,2)`; `isomorphisms(to:)` ⇒ {[0, 1, 2], [1, 2, 0], [2, 0, 1]}
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1, 2], [1, 2, 0], [2, 0, 1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 3)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 3)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-059 directed C3 against its reverse")
    func is059() {
        // `D: C(0,1,2)` → `D: C(2,1,0)`; `isomorphisms(to:)` ⇒ {[2, 1, 0], [1, 0, 2], [0, 2, 1]}
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: [2, 1, 0], edges: [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 2)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[2, 1, 0], [1, 0, 2], [0, 2, 1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 3)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 3)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-060 directed C3 against the transitive tournament")
    func is060() {
        // `D: C(0,1,2)` → `D: tt(3)`; `isIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 0)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-061 transitive tournament on 5: only one")
    func is061() throws {
        // `D: tt(5)` → `D: tt(5) ~map(2,1)`; `isomorphism(to:)` ⇒ [1, 3, 0, 2, 4]
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]
        ]
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 5), edges: patternEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let targetEdges: [[Int]] = [
            [1, 3], [1, 0], [1, 2], [1, 4], [3, 0], [3, 2], [3, 4], [0, 2], [0, 4], [2, 4]
        ]
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 5), edges: targetEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [1, 3, 0, 2, 4])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 3, 0, 2, 4])
        #expect(pattern.vertices.map { mapping.image(safe: $0) } == [1, 3, 0, 2, 4])
        #expect((0 ..< 5).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 5).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [2, 0, 3, 1, 4])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 1)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-062 Paley tournament on 7")
    func is062() {
        // `D: tpaley(7)` → `D: tpaley(7) ~map(3,2)`; `isomorphisms(to:).count` ⇒ #21
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [2, 6], [3, 0], [3, 4], [3, 5],
            [4, 1], [4, 5], [4, 6], [5, 0], [5, 2], [5, 6], [6, 0], [6, 1], [6, 3]
        ]
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 7), edges: patternEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let targetEdges: [[Int]] = [
            [2, 5], [2, 1], [2, 0], [5, 1], [5, 4], [5, 3], [1, 4], [1, 0], [1, 6], [4, 2], [4, 0], [4, 3],
            [0, 5], [0, 3], [0, 6], [3, 2], [3, 1], [3, 6], [6, 2], [6, 5], [6, 4]
        ]
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 7), edges: targetEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 21)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 21)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 21)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-063 2-cycle against two parallel arcs")
    func is063() {
        // `D: 0>1, 1>0` → `D: 0>1, 0>1`; `isIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 0)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-064 2-cycle against itself")
    func is064() {
        // `D: 0>1, 1>0` → `D: 0>1, 1>0`; `isomorphisms(to:)` ⇒ {[0, 1], [1, 0]}
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 2)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-065 same out-degrees, in-degrees differ")
    func is065() {
        // `D: 0>1, 0>2, 1>2` → `D: 0>1, 0>2, 2>0`; `isIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 0)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 0)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-066 loop at the tail against loop at the head")
    func is066() {
        // `D: 0>0, 0>1` → `D: 1>1, 0>1`; `isomorphism(to:)` ⇒ nil
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0], edges: [DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1)])
        // The catalog's value.
        #expect(pattern.isomorphism(to: target) == nil)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 0)
        #expect(pattern.isIsomorphic(to: target) == false)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-067 directed loop moves across the arc")
    func is067() throws {
        // `D: 0>0, 0>1` → `D: 1>1, 1>0`; `isomorphism(to:)` ⇒ [1, 0]
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0], edges: [DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 0)])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [1, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 0])
        #expect(pattern.vertices.map { mapping.image(safe: $0) } == [1, 0])
        #expect((0 ..< 2).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 2).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0, 1])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 1)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-068 orientations of C4: alternating against cyclic")
    func is068() {
        // `D: 0>1, 2>1, 2>3, 0>3` → `D: C(0,1,2,3)`; `isIsomorphic(to:)` ⇒ false
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 0)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-069 random digraph lcg(10,25,3) against a relabelling")
    func is069() {
        // `D: lcg(10,25,3)` → `D: lcg(10,25,3) ~map(3,4)`; `isomorphisms(to:).count` ⇒ #1
        let patternEdges: [[Int]] = [
            [9, 3], [5, 8], [4, 3], [3, 2], [6, 9], [8, 5], [7, 6], [5, 6], [1, 6], [5, 4], [9, 4], [1, 9],
            [5, 8], [1, 3], [8, 9], [5, 9], [0, 6], [0, 7], [5, 9], [9, 8], [1, 6], [6, 1], [5, 6], [4, 1],
            [1, 0]
        ]
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let targetEdges: [[Int]] = [
            [1, 3], [9, 8], [6, 3], [3, 0], [2, 1], [8, 9], [5, 2], [9, 2], [7, 2], [9, 6], [1, 6], [7, 1],
            [9, 8], [7, 3], [8, 1], [9, 1], [4, 2], [4, 5], [9, 1], [1, 8], [7, 2], [2, 7], [9, 2], [6, 7],
            [7, 4]
        ]
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 1)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-070 directed multigraph: three parallel arcs")
    func is070() throws {
        // `D: 0>1, 0>1, 0>1` → `D: 1>0, 1>0, 1>0`; `isomorphism(to:)` ⇒ [1, 0]
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 0)])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [1, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 0])
        #expect(pattern.vertices.map { mapping.image(safe: $0) } == [1, 0])
        #expect((0 ..< 2).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 2).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0, 1])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: Int] = [:]
        for edge in pattern.edges {
            patternPairs[[edge.source, edge.target], default: 0] += 1
        }
        var targetPairs: [[Int]: Int] = [:]
        for edge in target.edges {
            targetPairs[[edge.source, edge.target], default: 0] += 1
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 1)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }
}
