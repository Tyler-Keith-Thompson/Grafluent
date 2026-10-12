// The mapping's accessors (catalog IS-177, IS-179, IS-180).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Isomorphism values")
struct IsomorphismValueTests {
    @Test("IS-177 image(of:) a pattern vertex")
    func is177() throws {
        // `U: [5, 9, 7] 5-9` → `U: [2, 0, 4] 4-2`; `image(of: 7) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` ⇒ 0
        let pattern = Pseudograph<Int>(vertices: [5, 9, 7], edges: [UndirectedEdge(5, 9)])
        let target = Pseudograph<Int>(vertices: [2, 0, 4], edges: [UndirectedEdge(4, 2)])
        let patternColor: [Int: String] = [5: "a", 9: "b", 7: "c"]
        let targetColor: [Int: String] = [2: "a", 0: "c", 4: "b"]
        let mapping = try #require(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
        // The catalog's value.
        #expect(mapping.image(of: 7) == 0)
        #expect(try mapping.image(checked: 7) == 0)
        // Every accessor.
        #expect(Array(mapping.images) == [2, 4, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [2, 4, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [2, 4, 0])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [5, 7, 9])
    }

    @Test("IS-179 preimage(of:) a target vertex")
    func is179() throws {
        // `U: [5, 9, 7] 5-9` → `U: [2, 0, 4] 4-2`; `preimage(of: 2) after isomorphism(to:) vertexColor: G [a,b,c] H [a,c,b]` ⇒ 5
        let pattern = Pseudograph<Int>(vertices: [5, 9, 7], edges: [UndirectedEdge(5, 9)])
        let target = Pseudograph<Int>(vertices: [2, 0, 4], edges: [UndirectedEdge(4, 2)])
        let patternColor: [Int: String] = [5: "a", 9: "b", 7: "c"]
        let targetColor: [Int: String] = [2: "a", 0: "c", 4: "b"]
        let mapping = try #require(pattern.isomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
        // The catalog's value.
        #expect(mapping.preimage(of: 2) == 5)
        // Every accessor.
        #expect(Array(mapping.images) == [2, 4, 0])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [2, 4, 0])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [2, 4, 0])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [5, 7, 9])
    }

    @Test("IS-180 preimage(of:) a target vertex outside the image")
    func is180() throws {
        // `U: P(0,1,2)` → `U: [9] P(5,6,7), 9-5`; `preimage(of: 7) after subgraphIsomorphism(to:) vertexColor: G [x,y,z] H [x,y,z,w]` ⇒ nil
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: [9, 5, 6, 7], edges: [UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(9, 5)])
        let patternColor: [Int: String] = [0: "x", 1: "y", 2: "z"]
        let targetColor: [Int: String] = [9: "x", 5: "y", 6: "z", 7: "w"]
        let mapping = try #require(pattern.subgraphIsomorphism(to: target, vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }))
        // The catalog's value.
        #expect(mapping.preimage(of: 7) == nil)
        // Every accessor.
        #expect(Array(mapping.images) == [9, 5, 6])
        #expect(pattern.vertices.map { mapping.image(of: $0) } == [9, 5, 6])
        #expect(pattern.vertices.map { try? mapping.image(checked: $0) } == [9, 5, 6])
        #expect((0 ..< 3).map { target.vertex(atIndex: mapping.imageIndex(ofIndex: $0)) } == (0 ..< 3).map { mapping.image(of: pattern.vertex(atIndex: $0)) })
        #expect(target.vertices.map { mapping.preimage(of: $0) } == [0, 1, 2, nil])
    }
}
