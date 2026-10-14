// A BinaryTree draws through the tree layout by converting to a RootedTree (left child first), so
// siblings come out left to right. A lone child is centred under its parent whichever side it is
// on: the drawing does not show the side.

import GraphDrawing
import Testing
import Trees

@Suite("BinaryTree drawing")
struct BinaryTreeDrawingTests {
    @Test("RootedTree(Arborescence(binary)).reingoldTilfordLayout() puts left children left of right ones")
    func tidyDrawing() throws {
        let links: [Int: (Int?, Int?)] = [4: (2, 6), 2: (1, 3), 6: (nil, 7)]
        let tree = try #require(BinaryTree(root: 4) { links[$0] ?? (nil, nil) })
        let drawing = RootedTree(Arborescence(tree)).reingoldTilfordLayout()
        #expect(drawing.position(of: 4) == SIMD2(0, 0))
        for v in [4, 2, 1, 3, 6, 7] { #expect(drawing.position(of: v).y == Double(tree.depth(of: v))) }
        #expect(drawing.position(of: 2).x < drawing.position(of: 6).x)
        #expect(drawing.position(of: 1).x < drawing.position(of: 3).x)
        // 7 is 6's lone right child, drawn straight below it.
        #expect(drawing.position(of: 7).x == drawing.position(of: 6).x)
    }
}
