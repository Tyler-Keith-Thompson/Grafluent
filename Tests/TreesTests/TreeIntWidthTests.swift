// Trees at either `Int` width: rooting checks that a tree has fewer than 2³¹ vertices, a bound
// that is not a 32-bit shift where `Int` is 32 bits (arm64_32, wasm32).

import GraphProtocols
import Testing
import Trees

@Suite("Trees at either Int width")
struct TreeIntWidthTests {
    @Test("A path of 100 vertices becomes a Tree and roots at its first vertex")
    func pathRoots() throws {
        let tree = try #require(Tree(vertices: Array(0 ..< 100), edges: (0 ..< 99).map { UndirectedEdge($0, $0 + 1) }))
        #expect(tree.vertexCount == 100 && tree.edgeCount == 99)
        let rooted = RootedTree(tree, root: 0)
        #expect(rooted.height == 99)
        #expect(rooted.depth(of: 99) == 99)
    }
}
