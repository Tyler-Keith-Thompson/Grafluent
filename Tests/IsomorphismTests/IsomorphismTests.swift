// Isomorphism of undirected graphs (catalog IS-001 – IS-044): empty graphs, counts and degrees,
// 1-WL-equivalent pairs (C6 and 2C3, Shrikhande and rook(4), CFI), the automorphism counts of
// named graphs against relabelled copies, unique mappings of asymmetric graphs.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism")
struct IsomorphismTests {
    @Test("IS-001 empty graphs: the empty mapping")
    func is001() {
        // `U:` → `U:`; `isIsomorphic(to:)` ⇒ true
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>()
        // The catalog's value.
        #expect(pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-002 empty graphs: one mapping, the empty one")
    func is002() {
        // `U:` → `U:`; `isomorphisms(to:)` ⇒ {[]}
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>()
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-003 empty graphs: isomorphism(to:) is the empty mapping")
    func is003() throws {
        // `U:` → `U:`; `isomorphism(to:)` ⇒ []
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>()
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [])
        #expect((0 ..< 0).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 0).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-004 one vertex each")
    func is004() throws {
        // `U: [0]` → `U: [7]`; `isomorphism(to:)` ⇒ [7]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let target = Pseudograph<Int>(vertices: [7])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [7])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [7])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [7])
        #expect((0 ..< 1).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 1).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-005 different vertex counts")
    func is005() {
        // `U: [0]` → `U: [0, 1]`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2))
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-006 same vertex count, different edge counts")
    func is006() {
        // `U: P(0,1,2)` → `U: [0, 1, 2] 0-1`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-007 path against star, same counts, degrees differ")
    func is007() {
        // `U: P(0,1,2,3)` → `U: S(0;1..3)`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-008 C6 against two triangles: same degrees, 1-WL equal")
    func is008() {
        // `U: C(0,1,2,3,4,5)` → `U: C(0,1,2), C(3,4,5)`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-009 C6 against two triangles: no mapping")
    func is009() {
        // `U: C(0,1,2,3,4,5)` → `U: C(0,1,2), C(3,4,5)`; `isomorphism(to:)` ⇒ nil
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        // The catalog's value.
        #expect(pattern.isomorphism(to: target) == nil)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-010 C6 against a relabelled C6")
    func is010() {
        // `U: C(0,1,2,3,4,5)` → `U: C(0,1,2,3,4,5) ~map(5,2)`; `isomorphisms(to:).count` ⇒ #12
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(2, 1), UndirectedEdge(1, 0), UndirectedEdge(0, 5), UndirectedEdge(5, 4), UndirectedEdge(4, 3), UndirectedEdge(3, 2)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 12)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 12)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 12)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-011 C4: all eight")
    func is011() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `isomorphisms(to:)` ⇒ {[0, 1, 2, 3], [0, 3, 2, 1], [1, 0, 3, 2], [1, 2, 3, 0], [2, 1, 0, 3], [2, 3, 0, 1], [3, 0, 1, 2], [3, 2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1, 2, 3], [0, 3, 2, 1], [1, 0, 3, 2], [1, 2, 3, 0], [2, 1, 0, 3], [2, 3, 0, 1], [3, 0, 1, 2], [3, 2, 1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 8)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 8)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-012 P3 onto a relabelled P3: both")
    func is012() {
        // `U: P(0,1,2)` → `U: P(1,0,2)`; `isomorphisms(to:)` ⇒ {[1, 0, 2], [2, 0, 1]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: [1, 0, 2], edges: [UndirectedEdge(1, 0), UndirectedEdge(0, 2)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[1, 0, 2], [2, 0, 1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-013 path P5")
    func is013() {
        // `U: P(0,1,2,3,4)` → `U: P(0,1,2,3,4) ~map(2,1)`; `isomorphisms(to:).count` ⇒ #2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(1, 3), UndirectedEdge(3, 0), UndirectedEdge(0, 2), UndirectedEdge(2, 4)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 2)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-014 K4")
    func is014() {
        // `U: K(4)` → `U: K(4)`; `isomorphisms(to:).count` ⇒ #24
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 24)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 24)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 24)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-015 K5")
    func is015() {
        // `U: K(5)` → `U: K(5) ~map(2,3)`; `isomorphisms(to:).count` ⇒ #120
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [3, 0], [3, 2], [3, 4], [3, 1], [0, 2], [0, 4], [0, 1], [2, 4], [2, 1], [4, 1]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 120)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-016 K3,3")
    func is016() {
        // `U: KB(0..2;3..5)` → `U: KB(0..2;3..5) ~map(5,1)`; `isomorphisms(to:).count` ⇒ #72
        let patternEdges: [[Int]] = [
            [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]
        ]
        let pattern = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [1, 4], [1, 3], [1, 2], [0, 4], [0, 3], [0, 2], [5, 4], [5, 3], [5, 2]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 72)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 72)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 72)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-017 star K1,5")
    func is017() {
        // `U: S(0;1..5)` → `U: S(5;0..4)`; `isomorphisms(to:).count` ⇒ #120
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5)])
        let target = Pseudograph<Int>(vertices: [5, 0, 1, 2, 3, 4], edges: [UndirectedEdge(5, 0), UndirectedEdge(5, 1), UndirectedEdge(5, 2), UndirectedEdge(5, 3), UndirectedEdge(5, 4)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 120)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-018 five isolated vertices")
    func is018() {
        // `U: E(5)` → `U: E(5)`; `isomorphisms(to:).count` ⇒ #120
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 5))
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 120)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-019 grid 3x3")
    func is019() {
        // `U: grid(3,3)` → `U: grid(3,3) ~map(2,0)`; `isomorphisms(to:).count` ⇒ #8
        let patternEdges: [[Int]] = [
            [0, 1], [0, 3], [1, 2], [1, 4], [2, 5], [3, 4], [3, 6], [4, 5], [4, 7], [5, 8], [6, 7], [7, 8]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 9), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 2], [0, 6], [2, 4], [2, 8], [4, 1], [6, 8], [6, 3], [8, 1], [8, 5], [1, 7], [3, 5], [5, 7]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 9), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 8)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 8)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 8)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-020 cube Q3")
    func is020() {
        // `U: Q(3)` → `U: Q(3) ~map(3,1)`; `isomorphisms(to:).count` ⇒ #48
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [1, 4], [1, 7], [1, 5], [4, 2], [4, 0], [7, 2], [7, 3], [2, 6], [5, 0], [5, 3], [0, 6], [3, 6]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 48)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 48)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-021 hypercube Q4")
    func is021() {
        // `U: Q(4)` → `U: Q(4) ~map(5,3)`; `isomorphisms(to:).count` ⇒ #384
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [0, 8], [1, 3], [1, 5], [1, 9], [2, 3], [2, 6], [2, 10], [3, 7], [3, 11],
            [4, 5], [4, 6], [4, 12], [5, 7], [5, 13], [6, 7], [6, 14], [7, 15], [8, 9], [8, 10], [8, 12], [9, 11],
            [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [13, 15], [14, 15]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [3, 8], [3, 13], [3, 7], [3, 11], [8, 2], [8, 12], [8, 0], [13, 2], [13, 1], [13, 5], [2, 6], [2, 10],
            [7, 12], [7, 1], [7, 15], [12, 6], [12, 4], [1, 6], [1, 9], [6, 14], [11, 0], [11, 5], [11, 15], [0, 10],
            [0, 4], [5, 10], [5, 9], [10, 14], [15, 4], [15, 9], [4, 14], [9, 14]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 384)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 384)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 384)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-022 Petersen")
    func is022() {
        // `U: nx(petersen)` → `U: nx(petersen) ~map(3,4)`; `isomorphisms(to:).count` ⇒ #120
        let patternEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [4, 7], [4, 6], [4, 9], [7, 0], [7, 2], [0, 3], [0, 5], [3, 6], [3, 8], [6, 1], [9, 5], [9, 8],
            [2, 8], [2, 1], [5, 1]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 120)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-023 Petersen: some mapping")
    func is023() {
        // `U: nx(petersen)` → `U: nx(petersen) ~map(3,4)`; `isomorphism(to:)` ⇒ some (one of #120)
        let patternEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [4, 7], [4, 6], [4, 9], [7, 0], [7, 2], [0, 3], [0, 5], [3, 6], [3, 8], [6, 1], [9, 5], [9, 8],
            [2, 8], [2, 1], [5, 1]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let mapping = pattern.isomorphism(to: target)
        #expect(mapping != nil)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 120)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-024 Heawood")
    func is024() {
        // `U: nx(heawood)` → `U: nx(heawood) ~map(3,5)`; `isomorphisms(to:).count` ⇒ #336
        let patternEdges: [[Int]] = [
            [0, 1], [0, 13], [0, 5], [1, 2], [1, 10], [2, 3], [2, 7], [3, 4], [3, 12], [4, 5], [4, 9], [5, 6],
            [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [11, 12], [12, 13]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 14), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [5, 8], [5, 2], [5, 6], [8, 11], [8, 7], [11, 0], [11, 12], [0, 3], [0, 13], [3, 6], [3, 4], [6, 9],
            [9, 12], [9, 10], [12, 1], [1, 4], [1, 2], [4, 7], [7, 10], [10, 13], [13, 2]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 14), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 336)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 336)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 336)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-025 Möbius–Kantor")
    func is025() {
        // `U: nx(moebius_kantor)` → `U: nx(moebius_kantor) ~map(5,7)`; `isomorphisms(to:).count` ⇒ #96
        let patternEdges: [[Int]] = [
            [0, 1], [0, 15], [0, 5], [1, 2], [1, 12], [2, 3], [2, 7], [3, 4], [3, 14], [4, 5], [4, 9], [5, 6],
            [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [10, 15], [11, 12], [12, 13], [13, 14], [14, 15]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [7, 12], [7, 2], [7, 0], [12, 1], [12, 3], [1, 6], [1, 10], [6, 11], [6, 13], [11, 0], [11, 4], [0, 5],
            [5, 10], [5, 14], [10, 15], [15, 4], [15, 8], [4, 9], [9, 14], [9, 2], [14, 3], [3, 8], [8, 13], [13, 2]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 96)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 96)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 96)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-026 Desargues against the dodecahedron: both cubic on 20 vertices")
    func is026() {
        // `U: nx(desargues)` → `U: nx(dodecahedral)`; `isIsomorphic(to:)` ⇒ false
        let patternEdges: [[Int]] = [
            [0, 1], [0, 19], [0, 5], [1, 2], [1, 16], [2, 3], [2, 11], [3, 4], [3, 14], [4, 5], [4, 9], [5, 6],
            [6, 7], [6, 15], [7, 8], [7, 18], [8, 9], [8, 13], [9, 10], [10, 11], [10, 19], [11, 12], [12, 13], [12, 17],
            [13, 14], [14, 15], [15, 16], [16, 17], [17, 18], [18, 19]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 20), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 19], [0, 10], [1, 2], [1, 8], [2, 3], [2, 6], [3, 4], [3, 19], [4, 5], [4, 17], [5, 6],
            [5, 15], [6, 7], [7, 8], [7, 14], [8, 9], [9, 10], [9, 13], [10, 11], [11, 12], [11, 18], [12, 13], [12, 16],
            [13, 14], [14, 15], [15, 16], [16, 17], [17, 18], [18, 19]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 20), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-027 dodecahedron")
    func is027() {
        // `U: nx(dodecahedral)` → `U: nx(dodecahedral) ~map(3,7)`; `isomorphisms(to:).count` ⇒ #120
        let patternEdges: [[Int]] = [
            [0, 1], [0, 19], [0, 10], [1, 2], [1, 8], [2, 3], [2, 6], [3, 4], [3, 19], [4, 5], [4, 17], [5, 6],
            [5, 15], [6, 7], [7, 8], [7, 14], [8, 9], [9, 10], [9, 13], [10, 11], [11, 12], [11, 18], [12, 13], [12, 16],
            [13, 14], [14, 15], [15, 16], [16, 17], [17, 18], [18, 19]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 20), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [7, 10], [7, 4], [7, 17], [10, 13], [10, 11], [13, 16], [13, 5], [16, 19], [16, 4], [19, 2], [19, 18], [2, 5],
            [2, 12], [5, 8], [8, 11], [8, 9], [11, 14], [14, 17], [14, 6], [17, 0], [0, 3], [0, 1], [3, 6], [3, 15],
            [6, 9], [9, 12], [12, 15], [15, 18], [18, 1], [1, 4]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 20), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 120)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
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
        #expect(Set(pattern.isomorphisms(to: target)).count == 120)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-028 Paley(13)")
    func is028() {
        // `U: paley(13)` → `U: paley(13) ~map(2,5)`; `isomorphisms(to:).count` ⇒ #78
        let patternEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 3],
            [2, 5], [2, 6], [2, 11], [2, 12], [3, 4], [3, 6], [3, 7], [3, 12], [4, 5], [4, 7], [4, 8], [5, 6],
            [5, 8], [5, 9], [6, 7], [6, 9], [6, 10], [7, 8], [7, 10], [7, 11], [8, 9], [8, 11], [8, 12], [9, 10],
            [9, 12], [10, 11], [11, 12]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 13), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [5, 7], [5, 11], [5, 0], [5, 10], [5, 12], [5, 3], [7, 9], [7, 0], [7, 2], [7, 12], [7, 1], [9, 11],
            [9, 2], [9, 4], [9, 1], [9, 3], [11, 0], [11, 4], [11, 6], [11, 3], [0, 2], [0, 6], [0, 8], [2, 4],
            [2, 8], [2, 10], [4, 6], [4, 10], [4, 12], [6, 8], [6, 12], [6, 1], [8, 10], [8, 1], [8, 3], [10, 12],
            [10, 3], [12, 1], [1, 3]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 13), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 78)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 78)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 78)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-029 Shrikhande against the 4x4 rook's graph: both srg(16,6,2,2)")
    func is029() {
        // `U: shrikhande` → `U: rook(4)`; `isIsomorphic(to:)` ⇒ false
        let patternEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 5], [0, 12], [0, 15], [1, 2], [1, 5], [1, 6], [1, 12], [1, 13], [2, 3],
            [2, 6], [2, 7], [2, 13], [2, 14], [3, 4], [3, 7], [3, 14], [3, 15], [4, 5], [4, 7], [4, 8], [4, 9],
            [5, 6], [5, 9], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [8, 12], [8, 13],
            [9, 10], [9, 13], [9, 14], [10, 11], [10, 14], [10, 15], [11, 12], [11, 15], [12, 13], [12, 15], [13, 14], [14, 15]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 8], [0, 12], [1, 2], [1, 3], [1, 5], [1, 9], [1, 13], [2, 3],
            [2, 6], [2, 10], [2, 14], [3, 7], [3, 11], [3, 15], [4, 5], [4, 6], [4, 7], [4, 8], [4, 12], [5, 6],
            [5, 7], [5, 9], [5, 13], [6, 7], [6, 10], [6, 14], [7, 11], [7, 15], [8, 9], [8, 10], [8, 11], [8, 12],
            [9, 10], [9, 11], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [12, 15], [13, 14], [13, 15], [14, 15]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-030 Shrikhande")
    func is030() {
        // `U: shrikhande` → `U: shrikhande ~map(3,1)`; `isomorphisms(to:).count` ⇒ #192
        let patternEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 5], [0, 12], [0, 15], [1, 2], [1, 5], [1, 6], [1, 12], [1, 13], [2, 3],
            [2, 6], [2, 7], [2, 13], [2, 14], [3, 4], [3, 7], [3, 14], [3, 15], [4, 5], [4, 7], [4, 8], [4, 9],
            [5, 6], [5, 9], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [8, 12], [8, 13],
            [9, 10], [9, 13], [9, 14], [10, 11], [10, 14], [10, 15], [11, 12], [11, 15], [12, 13], [12, 15], [13, 14], [14, 15]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [1, 4], [1, 10], [1, 13], [1, 0], [1, 5], [1, 14], [4, 7], [4, 0], [4, 3], [4, 5], [4, 8], [7, 10],
            [7, 3], [7, 6], [7, 8], [7, 11], [10, 13], [10, 6], [10, 11], [10, 14], [13, 0], [13, 6], [13, 9], [13, 12],
            [0, 3], [0, 12], [0, 15], [3, 6], [3, 15], [3, 2], [6, 9], [6, 2], [9, 12], [9, 2], [9, 5], [9, 8],
            [12, 15], [12, 8], [12, 11], [15, 2], [15, 11], [15, 14], [2, 5], [2, 14], [5, 8], [5, 14], [8, 11], [11, 14]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 192)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 192)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 192)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-031 4x4 rook's graph")
    func is031() {
        // `U: rook(4)` → `U: rook(4) ~map(5,2)`; `isomorphisms(to:).count` ⇒ #1152
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 8], [0, 12], [1, 2], [1, 3], [1, 5], [1, 9], [1, 13], [2, 3],
            [2, 6], [2, 10], [2, 14], [3, 7], [3, 11], [3, 15], [4, 5], [4, 6], [4, 7], [4, 8], [4, 12], [5, 6],
            [5, 7], [5, 9], [5, 13], [6, 7], [6, 10], [6, 14], [7, 11], [7, 15], [8, 9], [8, 10], [8, 11], [8, 12],
            [9, 10], [9, 11], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [12, 15], [13, 14], [13, 15], [14, 15]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [2, 7], [2, 12], [2, 1], [2, 6], [2, 10], [2, 14], [7, 12], [7, 1], [7, 11], [7, 15], [7, 3], [12, 1],
            [12, 0], [12, 4], [12, 8], [1, 5], [1, 9], [1, 13], [6, 11], [6, 0], [6, 5], [6, 10], [6, 14], [11, 0],
            [11, 5], [11, 15], [11, 3], [0, 5], [0, 4], [0, 8], [5, 9], [5, 13], [10, 15], [10, 4], [10, 9], [10, 14],
            [15, 4], [15, 9], [15, 3], [4, 9], [4, 8], [9, 13], [14, 3], [14, 8], [14, 13], [3, 8], [3, 13], [8, 13]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1152)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 1152)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 1152)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-032 Frucht (asymmetric): the one mapping")
    func is032() throws {
        // `U: nx(frucht)` → `U: nx(frucht) ~map(5,1)`; `isomorphism(to:)` ⇒ [1, 6, 11, 4, 9, 2, 7, 0, 5, 10, 3, 8]
        let patternEdges: [[Int]] = [
            [0, 1], [0, 6], [0, 7], [1, 2], [1, 7], [2, 3], [2, 8], [3, 4], [3, 9], [4, 5], [4, 9], [5, 6],
            [5, 10], [6, 10], [7, 11], [8, 11], [8, 9], [10, 11]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [1, 6], [1, 7], [1, 0], [6, 11], [6, 0], [11, 4], [11, 5], [4, 9], [4, 10], [9, 2], [9, 10], [2, 7],
            [2, 3], [7, 3], [0, 8], [5, 8], [5, 10], [3, 8]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [1, 6, 11, 4, 9, 2, 7, 0, 5, 10, 3, 8])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 6, 11, 4, 9, 2, 7, 0, 5, 10, 3, 8])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [1, 6, 11, 4, 9, 2, 7, 0, 5, 10, 3, 8])
        #expect((0 ..< 12).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 12).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9, 2])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-033 Frucht onto itself: only the identity")
    func is033() {
        // `U: nx(frucht)` → `U: nx(frucht)`; `isomorphisms(to:)` ⇒ {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]}
        let patternEdges: [[Int]] = [
            [0, 1], [0, 6], [0, 7], [1, 2], [1, 7], [2, 3], [2, 8], [3, 4], [3, 9], [4, 5], [4, 9], [5, 6],
            [5, 10], [6, 10], [7, 11], [8, 11], [8, 9], [10, 11]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 6], [0, 7], [1, 2], [1, 7], [2, 3], [2, 8], [3, 4], [3, 9], [4, 5], [4, 9], [5, 6],
            [5, 10], [6, 10], [7, 11], [8, 11], [8, 9], [10, 11]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-034 asymmetric tree on 7 vertices: the one mapping")
    func is034() throws {
        // `U: P(0,1,2,3,4,5), 2-6` → `U: P(6,5,4,3,2,1), 4-0`; `isomorphism(to:)` ⇒ [6, 5, 4, 3, 2, 1, 0]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 7), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(2, 6)])
        let target = Pseudograph<Int>(vertices: [6, 5, 4, 3, 2, 1, 0], edges: [UndirectedEdge(6, 5), UndirectedEdge(5, 4), UndirectedEdge(4, 3), UndirectedEdge(3, 2), UndirectedEdge(2, 1), UndirectedEdge(4, 0)])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [6, 5, 4, 3, 2, 1, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [6, 5, 4, 3, 2, 1, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [6, 5, 4, 3, 2, 1, 0])
        #expect((0 ..< 7).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 7).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0, 1, 2, 3, 4, 5, 6])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-035 two trees with one degree sequence")
    func is035() {
        // `U: P(0,1,2,3,4), 1-5` → `U: P(0,1,2,3,4), 2-5`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(1, 5)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(2, 5)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-036 karate club against a relabelling")
    func is036() {
        // `U: nx(karate_club)` → `U: nx(karate_club) ~map(5,3)`; `isomorphisms(to:).count` ⇒ #480
        let patternEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 10], [0, 11], [0, 12], [0, 13],
            [0, 17], [0, 19], [0, 21], [0, 31], [1, 2], [1, 3], [1, 7], [1, 13], [1, 17], [1, 19], [1, 21], [1, 30],
            [2, 3], [2, 7], [2, 8], [2, 9], [2, 13], [2, 27], [2, 28], [2, 32], [3, 7], [3, 12], [3, 13], [4, 6],
            [4, 10], [5, 6], [5, 10], [5, 16], [6, 16], [8, 30], [8, 32], [8, 33], [9, 33], [13, 33], [14, 32], [14, 33],
            [15, 32], [15, 33], [18, 32], [18, 33], [19, 33], [20, 32], [20, 33], [22, 32], [22, 33], [23, 25], [23, 27], [23, 29],
            [23, 32], [23, 33], [24, 25], [24, 27], [24, 31], [25, 31], [26, 29], [26, 33], [27, 33], [28, 31], [28, 33], [29, 32],
            [29, 33], [30, 32], [30, 33], [31, 32], [31, 33], [32, 33]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 34), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [3, 8], [3, 13], [3, 18], [3, 23], [3, 28], [3, 33], [3, 4], [3, 9], [3, 19], [3, 24], [3, 29], [3, 0],
            [3, 20], [3, 30], [3, 6], [3, 22], [8, 13], [8, 18], [8, 4], [8, 0], [8, 20], [8, 30], [8, 6], [8, 17],
            [13, 18], [13, 4], [13, 9], [13, 14], [13, 0], [13, 2], [13, 7], [13, 27], [18, 4], [18, 29], [18, 0], [23, 33],
            [23, 19], [28, 33], [28, 19], [28, 15], [33, 15], [9, 17], [9, 27], [9, 32], [14, 32], [0, 32], [5, 27], [5, 32],
            [10, 27], [10, 32], [25, 27], [25, 32], [30, 32], [1, 27], [1, 32], [11, 27], [11, 32], [16, 26], [16, 2], [16, 12],
            [16, 27], [16, 32], [21, 26], [21, 2], [21, 22], [26, 22], [31, 12], [31, 32], [2, 32], [7, 22], [7, 32], [12, 27],
            [12, 32], [17, 27], [17, 32], [22, 27], [22, 32], [27, 32]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 34), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 480)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 480)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 480)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-037 isolated vertex kept: K2 + K1")
    func is037() {
        // `U: [0, 1, 2] 0-1` → `U: [0, 1, 2] 2-1`; `isomorphisms(to:)` ⇒ {[1, 2, 0], [2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(2, 1)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[1, 2, 0], [2, 1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-038 disconnected: 2K2 against P3 + K1")
    func is038() {
        // `U: 0-1, 2-3` → `U: [0, 1, 2, 3] 0-1, 1-2`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-039 disconnected: 2C3 + K1 against a relabelling")
    func is039() {
        // `U: [6] C(0,1,2), C(3,4,5)` → `U: [0] C(1,2,3), C(4,5,6)`; `isomorphisms(to:).count` ⇒ #72
        let pattern = Pseudograph<Int>(vertices: [6, 0, 1, 2, 3, 4, 5], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 7), edges: [UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 1), UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 4)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 72)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 72)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 72)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-040 vertex names: images are target vertices, in pattern `vertices` order")
    func is040() throws {
        // `U: [5, 9, 7] 5-9` → `U: [2, 0, 4] 4-2`; `isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` ⇒ [2, 4, 0]
        let pattern = Pseudograph<Int>(vertices: [5, 9, 7], edges: [UndirectedEdge(5, 9)])
        let target = Pseudograph<Int>(vertices: [2, 0, 4], edges: [UndirectedEdge(4, 2)])
        let patternColor: [Int: String] = [5: "a", 9: "b", 7: "c"]
        let targetColor: [Int: String] = [2: "a", 0: "c", 4: "b"]
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
        #expect(Array(mapping.images) == [2, 4, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [2, 4, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [2, 4, 0])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [5, 7, 9])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included, with equal vertex colours.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            guard pattern.vertices.allSatisfy({ patternColor[$0] == targetColor[image[$0]!] }) else { return false }
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 1)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-041 CFI over K4 against its twisted copy: 1-WL equal, not isomorphic")
    func is041() {
        // `U: cfi(K(4))` → `U: cfi~(K(4))`; `isIsomorphic(to:)` ⇒ false
        let patternEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 14], [5, 15], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 15], [5, 14], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-042 CFI over K4 against a relabelling")
    func is042() {
        // `U: cfi(K(4))` → `U: cfi(K(4)) ~map(7,3)`; `isomorphisms(to:).count` ⇒ #192
        let patternEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 14], [5, 15], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [3, 31], [3, 5], [3, 19], [10, 38], [10, 12], [10, 19], [17, 38], [17, 5], [17, 26], [24, 31], [24, 12], [24, 26],
            [33, 21], [33, 35], [33, 9], [0, 28], [0, 2], [0, 9], [7, 28], [7, 35], [7, 16], [14, 21], [14, 2], [14, 16],
            [23, 11], [23, 25], [23, 39], [30, 18], [30, 32], [30, 39], [37, 18], [37, 25], [37, 6], [4, 11], [4, 32], [4, 6],
            [13, 1], [13, 15], [13, 29], [20, 8], [20, 22], [20, 29], [27, 8], [27, 15], [27, 36], [34, 1], [34, 22], [34, 36],
            [31, 21], [38, 28], [5, 11], [12, 18], [19, 1], [26, 8], [35, 25], [2, 32], [9, 15], [16, 22], [39, 29], [6, 36]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 192)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0
                    return a == b
                }
            }
        }
        #expect(all.count == 192)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 192)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-043 random graph lcg(12,24,1) against a relabelling")
    func is043() {
        // `U: lcg(12,24,1)` → `U: lcg(12,24,1) ~map(5,7)`; `isomorphisms(to:).count` ⇒ #1
        let patternEdges: [[Int]] = [
            [2, 9], [0, 6], [6, 11], [2, 10], [9, 10], [3, 10], [2, 4], [10, 11], [4, 9], [7, 1], [2, 6], [9, 8],
            [0, 8], [9, 4], [11, 10], [0, 5], [2, 6], [6, 10], [4, 1], [11, 4], [2, 4], [9, 10], [0, 9], [11, 10]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [5, 4], [7, 1], [1, 2], [5, 9], [4, 9], [10, 9], [5, 3], [9, 2], [3, 4], [6, 0], [5, 1], [4, 11],
            [7, 11], [4, 3], [2, 9], [7, 8], [5, 1], [1, 9], [3, 0], [2, 3], [5, 3], [4, 9], [7, 4], [2, 9]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 1)
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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

    @Test("IS-044 lcg(12,24,1) against lcg(12,24,2)")
    func is044() {
        // `U: lcg(12,24,1)` → `U: lcg(12,24,2)`; `isIsomorphic(to:)` ⇒ false
        let patternEdges: [[Int]] = [
            [2, 9], [0, 6], [6, 11], [2, 10], [9, 10], [3, 10], [2, 4], [10, 11], [4, 9], [7, 1], [2, 6], [9, 8],
            [0, 8], [9, 4], [11, 10], [0, 5], [2, 6], [6, 10], [4, 1], [11, 4], [2, 4], [9, 10], [0, 9], [11, 10]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [4, 6], [0, 8], [0, 6], [9, 2], [11, 2], [0, 6], [6, 5], [2, 7], [8, 2], [8, 2], [1, 6], [11, 6],
            [11, 7], [6, 4], [9, 10], [3, 1], [5, 4], [0, 4], [3, 8], [4, 8], [8, 11], [10, 2], [7, 1], [6, 8]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the number of edges between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
}
