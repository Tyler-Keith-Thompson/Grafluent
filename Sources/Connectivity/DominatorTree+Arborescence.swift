import GraphProtocols
import Trees

extension Arborescence {
    /// The dominator tree as an arborescence rooted at its root: every vertex the root reaches,
    /// each with its immediate dominator as parent (NetworkX's `immediate_dominators` map, LLVM's
    /// `DominatorTree`). A post-dominator tree converts the same way: each vertex that reaches
    /// the exit, with its immediate post-dominator as parent.
    ///
    /// Vertices are listed in vertex-index order (`vertices` order without indices), the
    /// unreached ones left out, so the root need not come first. Edge positions are the
    /// arborescence's own, in vertex order: edge k leads to the k-th listed vertex other than
    /// the root, counting from 0. `children(of:)` lists a vertex's children in the order
    /// `DominatorTree.children(of:)` does. O(n); the vertices are hashed once, into the
    /// arborescence's lookup table, unless they are the `Int`s `0..<k` in order.
    @inlinable
    public init<G: DirectedGraph>(_ tree: DominatorTree<G>) where G.Vertex == Vertex {
        let n = tree._idom.count
        // Each reached vertex number's number in the arborescence.
        var number = [Int](repeating: -1, count: n)
        var vertices = ContiguousArray<Vertex>()
        for v in 0 ..< n where tree._enter[v] >= 0 {
            number[v] = vertices.count
            vertices.append(tree._vertices.vertex(v))
        }
        var parents = [Int](repeating: -1, count: vertices.count)
        for v in 0 ..< n where tree._idom[v] >= 0 { parents[number[v]] = number[tree._idom[v]] }
        self.init(vertices: vertices, parents: parents)
    }
}
