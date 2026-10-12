# Planted bugs for Traversal's Walks results; run with `just mutate Traversal`. See
# scripts/mutate.py. (Traversal's search itself was mutation-tested before these tools existed.)
#
# Known equivalent mutants (they survive by design): none yet.

TESTS = ["TraversalTests"]

MUTANTS = [
    Mutant("stepedgeindexed", "StepEdges.swift",
           "$0.0 == w",
           "true"),
    Mutant("stepedgelookup", "StepEdges.swift",
           "self.target(ofEdgeAt: $0) == target",
           "true"),
    Mutant("cycleclosing", "TopologicalSort.swift",
           "_stepEdges(ordered + [ordered[0]], search.ids)",
           "_stepEdges(ordered + [ordered[ordered.count - 1]], search.ids)"),
    Mutant("forwardedge", "Reachability.swift",
           "                            forwardEdge[w] = e",
           "", mode="stmt"),
    Mutant("backwardedge", "Reachability.swift",
           "            edges.append(backwardEdge[v]!)",
           "            edges.append(forwardEdge[v] ?? backwardEdge[v]!)", mode="stmt"),
    Mutant("forwardorder", "Reachability.swift",
           "        edges.reverse()",
           "", mode="stmt"),
    # The checked: spellings: a dropped membership check reaches the trapping spelling, and a
    # swapped call returns the other direction's set.
    Mutant("descendantschecked", "Reachability.swift",
           "        guard contains(vertex) else { throw VertexNotFound() }",
           "", mode="stmt", nth=0),
    Mutant("ancestorschecked", "Reachability.swift",
           "        guard contains(vertex) else { throw VertexNotFound() }",
           "", mode="stmt", nth=1),
    Mutant("descendantscheckedvalue", "Reachability.swift",
           "        return descendants(of: vertex)",
           "        return []", mode="stmt"),
    Mutant("ancestorscheckedvalue", "Reachability.swift",
           "        return ancestors(of: vertex)",
           "        return []", mode="stmt"),

    # reuse pass (D): search trees
    Mutant("st_parent", "SearchTrees.swift",
           "search.discovery[p]",
           "p"),
    # The shared conversion in Trees: Int vertices taken as 0..<n in order whatever they are.
    Mutant("st_dense", "Arborescence.swift",
           "_TreeLayout.numbering(vertices)",
           "(slots: [Vertex: Int](), dense: true)", module="Trees"),
    # The search's depthLimit argument: the 6th and 12th `depthLimit` in the file.
    Mutant("st_bfs_limit", "SearchTrees.swift",
           "depthLimit",
           "nil", nth=5),
    Mutant("st_dfs_limit", "SearchTrees.swift",
           "depthLimit",
           "nil", nth=11),
    Mutant("st_bfs_negative", "SearchTrees.swift",
           '        precondition(depthLimit.map { $0 >= 0 } ?? true, "A depth limit cannot be negative")',
           "", mode="stmt", nth=0),
    Mutant("st_dfs_negative", "SearchTrees.swift",
           '        precondition(depthLimit.map { $0 >= 0 } ?? true, "A depth limit cannot be negative")',
           "", mode="stmt", nth=1),
]
