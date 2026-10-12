// Self-loops and parallel edges (catalog IS-045 – IS-056): a loop is an edge, multiplicities count.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism with self-loops and parallel edges")
struct IsomorphismLoopTests {
    @Test("IS-045 loop at the end of an edge, either end")
    func is045() throws {
        // `U: 0-0, 0-1` → `U: 1-1, 0-1`; `isomorphism(to:)` ⇒ [1, 0]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: [1, 0], edges: [UndirectedEdge(1, 1), UndirectedEdge(0, 1)])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [1, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [1, 0])
        #expect((0 ..< 2).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 2).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0, 1])
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

    @Test("IS-046 a loop counts 2: degrees (2,1,1) both, still not isomorphic")
    func is046() {
        // `U: 0-0, 1-2` → `U: P(0,1,2)`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
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

    @Test("IS-047 loop against no loop")
    func is047() {
        // `U: [0] 0-0` → `U: [0]`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 1))
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

    @Test("IS-048 two loops against one")
    func is048() {
        // `U: 0-0, 0-0` → `U: 0-0, 1-1`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 1)])
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

    @Test("IS-049 two loops on one vertex against two loops on one vertex")
    func is049() throws {
        // `U: 0-0, 0-0, 0-1` → `U: 0-1, 1-1, 1-1`; `isomorphism(to:)` ⇒ [1, 0]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 1)])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [1, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [1, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [1, 0])
        #expect((0 ..< 2).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 2).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [1, 0])
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

    @Test("IS-050 parallel pair moves to the other edge")
    func is050() throws {
        // `U: 0=1, 1-2` → `U: 0-1, 1=2`; `isomorphism(to:)` ⇒ [2, 1, 0]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        let mapping = try #require(pattern.isomorphism(to: target))
        #expect(Array(mapping.images) == [2, 1, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [2, 1, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [2, 1, 0])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [2, 1, 0])
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

    @Test("IS-051 parallel pair against a path: same degrees")
    func is051() {
        // `U: 0=1, 2-3` → `U: P(0,1,2,3)`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
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

    @Test("IS-052 multiplicity 3 against 2 + 1 elsewhere")
    func is052() {
        // `U: 0=1, 0-1` → `U: 0=1, 1-2`; `isIsomorphic(to:)` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
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

    @Test("IS-053 doubled triangle")
    func is053() {
        // `U: 0=1, 1=2, 2=0` → `U: 0=1, 1=2, 2=0`; `isomorphisms(to:).count` ⇒ #6
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 0)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(all.count == 6)
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
        #expect(all.count == 6)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target)).count == 6)
        #expect(pattern.isIsomorphic(to: target) == true)
        let first = pattern.isomorphism(to: target).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target).map { Array($0.images) } == first)
    }

    @Test("IS-054 doubled C4")
    func is054() {
        // `U: 0=1, 1=2, 2=3, 3=0` → `U: 0=1, 1=2, 2=3, 3=0`; `isomorphisms(to:).count` ⇒ #8
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 0)])
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

    @Test("IS-055 bouquet: one vertex, three loops")
    func is055() {
        // `U: 0-0, 0-0, 0-0` → `U: 0-0, 0-0, 0-0`; `isomorphisms(to:)` ⇒ {[0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[0]])
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

    @Test("IS-056 loops and parallel edges together")
    func is056() {
        // `U: 0-0, 0=1, 1-2, 2-2` → `U: 2-2, 2=1, 1-0, 0-0`; `isomorphisms(to:)` ⇒ {[2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        let target = Pseudograph<Int>(vertices: [2, 1, 0], edges: [UndirectedEdge(2, 2), UndirectedEdge(2, 1), UndirectedEdge(2, 1), UndirectedEdge(1, 0), UndirectedEdge(0, 0)])
        // The catalog's value.
        let all = pattern.isomorphisms(to: target).map { Array($0.images) }
        #expect(Set(all) == [[2, 1, 0]])
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
}
