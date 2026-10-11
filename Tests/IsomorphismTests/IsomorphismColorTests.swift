// Colours (catalog IS-071 – IS-086): vertex colours equal, edge colours as multisets per pair.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism with vertex and edge colours")
struct IsomorphismColorTests {
    @Test("IS-071 C4, colours r r b b against r b r b")
    func is071() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `isIsomorphic(to:) vertexColor: G [r,r,b,b] H [r,b,r,b]` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternColor: [Int: String] = [0: "r", 1: "r", 2: "b", 3: "b"]
        let targetColor: [Int: String] = [0: "r", 1: "b", 2: "r", 3: "b"]
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
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
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 0)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-072 C4, colours r r b b against b r r b")
    func is072() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `isomorphisms(to:) vertexColor: G [r,r,b,b] H [b,r,r,b]` ⇒ {[1, 2, 3, 0], [2, 1, 0, 3]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternColor: [Int: String] = [0: "r", 1: "r", 2: "b", 3: "b"]
        let targetColor: [Int: String] = [0: "b", 1: "r", 2: "r", 3: "b"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(Set(all) == [[1, 2, 3, 0], [2, 1, 0, 3]])
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
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 2)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-073 colour class sizes differ")
    func is073() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `isIsomorphic(to:) vertexColor: G [r,r,r,b] H [r,r,b,b]` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternColor: [Int: String] = [0: "r", 1: "r", 2: "r", 3: "b"]
        let targetColor: [Int: String] = [0: "r", 1: "r", 2: "b", 3: "b"]
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
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
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 0)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-074 a colour missing from the target")
    func is074() {
        // `U: K(3)` → `U: K(3)`; `isIsomorphic(to:) vertexColor: G [r,r,g] H [r,r,b]` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let patternColor: [Int: String] = [0: "r", 1: "r", 2: "g"]
        let targetColor: [Int: String] = [0: "r", 1: "r", 2: "b"]
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
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
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 0)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-075 Petersen with one vertex coloured: its stabiliser")
    func is075() {
        // `U: nx(petersen)` → `U: nx(petersen)`; `isomorphisms(to:).count vertexColor: G [x,o,o,o,o,o,o,o,o,o] H [x,o,o,o,o,o,o,o,o,o]` ⇒ #12
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
        let patternColor: [Int: String] = [0: "x", 1: "o", 2: "o", 3: "o", 4: "o", 5: "o", 6: "o", 7: "o", 8: "o", 9: "o"]
        let targetColor: [Int: String] = [0: "x", 1: "o", 2: "o", 3: "o", 4: "o", 5: "o", 6: "o", 7: "o", 8: "o", 9: "o"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(all.count == 12)
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
        #expect(all.count == 12)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 12)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-076 Petersen, the coloured vertex elsewhere")
    func is076() {
        // `U: nx(petersen)` → `U: nx(petersen)`; `isomorphisms(to:).count vertexColor: G [x,o,o,o,o,o,o,o,o,o] H [o,o,o,o,o,o,o,x,o,o]` ⇒ #12
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
        let patternColor: [Int: String] = [0: "x", 1: "o", 2: "o", 3: "o", 4: "o", 5: "o", 6: "o", 7: "o", 8: "o", 9: "o"]
        let targetColor: [Int: String] = [0: "o", 1: "o", 2: "o", 3: "o", 4: "o", 5: "o", 6: "o", 7: "x", 8: "o", 9: "o"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(all.count == 12)
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
        #expect(all.count == 12)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 12)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-077 uniform colours change nothing")
    func is077() {
        // `U: nx(petersen)` → `U: nx(petersen) ~map(3,4)`; `isomorphisms(to:).count vertexColor: G [0,0,0,0,0,0,0,0,0,0] H [0,0,0,0,0,0,0,0,0,0]` ⇒ #120
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
        let patternColor: [Int: String] = [0: "0", 1: "0", 2: "0", 3: "0", 4: "0", 5: "0", 6: "0", 7: "0", 8: "0", 9: "0"]
        let targetColor: [Int: String] = [0: "0", 1: "0", 2: "0", 3: "0", 4: "0", 5: "0", 6: "0", 7: "0", 8: "0", 9: "0"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(all.count == 120)
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
        #expect(all.count == 120)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! })).count == 120)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) } == first)
    }

    @Test("IS-078 distinct colours: at most one mapping")
    func is078() {
        // `U: K(4)` → `U: K(4)`; `isomorphisms(to:) vertexColor: G [a,b,c,d] H [d,c,b,a]` ⇒ {[3, 2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let patternColor: [Int: String] = [0: "a", 1: "b", 2: "c", 3: "d"]
        let targetColor: [Int: String] = [0: "d", 1: "c", 2: "b", 3: "a"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }).map { Array($0.images) }
        #expect(Set(all) == [[3, 2, 1, 0]])
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

    @Test("IS-079 edge colours on C4: a a b b against a b a b")
    func is079() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `isIsomorphic(to:) edgeColor: G [a,a,b,b] H [a,b,a,b]` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["a", "a", "b", "b"]
        let targetEdgeColor = ["a", "b", "a", "b"]
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 0)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-080 edge colours on C4: a a b b against b a a b")
    func is080() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `isomorphisms(to:) edgeColor: G [a,a,b,b] H [b,a,a,b]` ⇒ {[1, 2, 3, 0], [3, 2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["a", "a", "b", "b"]
        let targetEdgeColor = ["b", "a", "a", "b"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[1, 2, 3, 0], [3, 2, 1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 2)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-081 edge colours on a triangle: one of each")
    func is081() {
        // `U: C(0,1,2)` → `U: C(0,1,2)`; `isomorphisms(to:) edgeColor: G [a,b,c] H [c,a,b]` ⇒ {[1, 2, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let patternEdgeColor = ["a", "b", "c"]
        let targetEdgeColor = ["c", "a", "b"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[1, 2, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 1)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-082 parallel pair: colours {a, b} against {a, a}")
    func is082() {
        // `U: 0=1` → `U: 0=1`; `isIsomorphic(to:) edgeColor: G [a,b] H [a,a]` ⇒ false
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let patternEdgeColor = ["a", "b"]
        let targetEdgeColor = ["a", "a"]
        // The catalog's value.
        #expect(!pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }))
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(all.count == 0)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 0)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first == nil)
    }

    @Test("IS-083 parallel pair: colours {a, b} against {b, a}")
    func is083() {
        // `U: 0=1` → `U: 0=1`; `isomorphisms(to:) edgeColor: G [a,b] H [b,a]` ⇒ {[0, 1], [1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let patternEdgeColor = ["a", "b"]
        let targetEdgeColor = ["b", "a"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[0, 1], [1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        #expect(all.count == 2)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 2)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-084 loop colours")
    func is084() {
        // `U: 0-0, 0-1, 1-1` → `U: 0-0, 0-1, 1-1`; `isomorphisms(to:) edgeColor: G [a,c,b] H [b,c,a]` ⇒ {[1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let patternEdgeColor = ["a", "c", "b"]
        let targetEdgeColor = ["b", "c", "a"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 1)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-085 vertex and edge colours together")
    func is085() {
        // `U: P(0,1,2)` → `U: P(0,1,2)`; `isomorphisms(to:) vertexColor: G [r,b,r] H [r,b,r] edgeColor: G [x,y] H [y,x]` ⇒ {[2, 1, 0]}
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternColor: [Int: String] = [0: "r", 1: "b", 2: "r"]
        let targetColor: [Int: String] = [0: "r", 1: "b", 2: "r"]
        let patternEdgeColor = ["x", "y"]
        let targetEdgeColor = ["y", "x"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[2, 1, 0]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (both orders for an edge, once for a self-loop); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included, with equal vertex colours.
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
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            guard pattern.vertices.allSatisfy({ patternColor[$0] == targetColor[image[$0]!] }) else { return false }
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 1)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }

    @Test("IS-086 directed: arc colours")
    func is086() {
        // `D: C(0,1,2)` → `D: C(0,1,2)`; `isomorphisms(to:) edgeColor: G [a,a,b] H [a,b,a]` ⇒ {[2, 0, 1]}
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let patternEdgeColor = ["a", "a", "b"]
        let targetEdgeColor = ["a", "b", "a"]
        // The catalog's value.
        let all = pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(Set(all) == [[2, 0, 1]])
        // The family on the same arguments: every mapping, the yes/no answer and the first mapping.
        // api.md's definition: m(u, v) is the multiset of edge colours between u and v (arcs from u to v); a mapping is a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included.
        var patternPairs: [[Int]: [String]] = [:]
        for (position, edge) in pattern.edges.enumerated() {
            patternPairs[[edge.source, edge.target], default: []].append(patternEdgeColor[position])
        }
        var targetPairs: [[Int]: [String]] = [:]
        for (position, edge) in target.edges.enumerated() {
            targetPairs[[edge.source, edge.target], default: []].append(targetEdgeColor[position])
        }
        let isValid = { (images: [Int]) -> Bool in
            guard images.count == target.vertexCount && images.count == pattern.vertexCount, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }
            let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))
            return pattern.vertices.allSatisfy { u in
                pattern.vertices.allSatisfy { v in
                    let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()
                    return a == b
                }
            }
        }
        #expect(all.count == 1)
        #expect(Set(all).count == all.count)
        #expect(all.allSatisfy(isValid))
        #expect(Set(pattern.isomorphisms(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] })).count == 1)
        #expect(pattern.isIsomorphic(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }) == true)
        let first = pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) }
        #expect(first.map(isValid) == true)
        // No randomness: a second call gives the same mapping.
        #expect(pattern.isomorphism(to: target, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }).map { Array($0.images) } == first)
    }
}
