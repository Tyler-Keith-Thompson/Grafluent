# Planted bugs for Trees; run with `just mutate Trees`. See scripts/mutate.py.
#
# Known equivalent mutants (defensive checks that an earlier or later check covers):
#   edgecount, istreecount  fewer than n − 1 edges cannot reach every vertex anyway.
#   forestcount             more than n − 1 edges always meet the cycle check.
#   orientation/oneincoming each implies the other for n − 1 arcs with one root.
#   tworoots                two roots leave n − 2 edges, which fail the count.
#   selfparent              a self-parent is a cycle.
#   endrange                every caller has already checked the ends' range.
#   containsedge            a loop's vertex is never its own parent.
#   forestsingle            an empty forest has no tree to build.
#   pruferleaf              the next vertex is never the pointer's (removed) leaf.
#   firstappear             missing a new endpoint falls back to hashing: slower, the same answer.
#   parentskip              skipping the parent vertex instead of its edge still finds a parallel
#                           pair, from the parent's row.

TESTS = ["TreesTests"]

MUTANTS = [
    # Validation
    Mutant("edgecount", "TreeLayout.swift", "m == n - 1", "m <= n - 1", nth=0),
    Mutant("forestcount", "TreeLayout.swift", "m <= max(n - 1, 0)", "m <= n"),
    Mutant("cycle", "TreeLayout.swift", "                guard nodes[w].depth < 0 else { return false }", "                guard nodes[w].depth < 0 else { continue }", mode="stmt"),
    Mutant("parentskip", "TreeLayout.swift", "e == node.parentEdge", "rowNeighbors[k] == node.parent"),
    Mutant("orientation", "TreeLayout.swift", "                if oriented, ends[2 * e] != v { return false }", "", mode="stmt"),
    Mutant("reachall", "TreeLayout.swift", "        guard preorder.count == n else { return false }", "", mode="stmt"),
    Mutant("endrange", "TreeLayout.swift", "            guard UInt(bitPattern: x) < UInt(bitPattern: n) else { return nil }", "", mode="stmt"),
    Mutant("oneincoming", "Arborescence.swift", "            if incoming[t] > 1 { return nil }", "", mode="stmt"),
    Mutant("tworoots", "RootedTree.swift", "                guard root < 0 else { return nil }", "", mode="stmt"),
    Mutant("selfparent", "RootedTree.swift", "                guard p != v else { return nil }", "", mode="stmt"),
    Mutant("parentrange", "RootedTree.swift", "            guard p >= 0, p < n else { return nil }", "            guard p < n else { return nil }", mode="stmt"),
    Mutant("istreecount", "Recognition.swift", "edgeCount == n - 1", "edgeCount <= n - 1", nth=0),
    Mutant("treereach", "Recognition.swift", "reached == n", "true", nth=0),
    Mutant("arbreach", "Recognition.swift", "reached == n", "true", nth=1),

    # The rooting
    Mutant("twin", "TreeLayout.swift", "twin[k]", "(twin[k] == 0 ? 0 : twin[k] - 1)"),
    Mutant("sizes", "TreeLayout.swift", "                    if p >= 0 { nodes[p].size += nodes[v].size }", "", mode="stmt"),
    Mutant("height", "TreeLayout.swift", "                if depth > height { height = depth }", "", mode="stmt"),
    Mutant("component", "TreeLayout.swift", "                nodes[w].component = tree", "                nodes[w].component = 0", mode="stmt"),
    Mutant("rootfirst", "TreeLayout.swift", "nodes[next].depth >= 0", "nodes[next].depth > 0"),
    Mutant("reroot", "TreeLayout.swift", "roots[0] == root", "true"),

    # Queries
    Mutant("ancestorstrict", "TreeLayout.swift", "pa < pb && pb < pa + nodes[a].size", "pa <= pb && pb < pa + nodes[a].size"),
    Mutant("postorder", "RootedTree.swift", "node.preorderPosition + node.size - 1 - node.depth", "node.preorderPosition + node.size - 1 - (node.depth == 0 ? 0 : 1)"),
    Mutant("descendants", "RootedTree.swift", "(start + 1) ..< (start + nodes[v].size)", "start ..< (start + nodes[v].size)"),
    Mutant("childhole", "RootedTree.swift", "position < _hole ? position : position + 1", "position <= _hole ? position : position + 1"),
    Mutant("pathorder", "TreeLayout.swift", "up.append(contentsOf: down.dropLast().reversed())", "up.append(contentsOf: down.dropLast())"),
    Mutant("pathcomponent", "TreeLayout.swift", "        guard nodes[a].component == nodes[b].component else { return nil }", "", mode="stmt"),
    Mutant("arbpath", "Arborescence.swift", "a == b || _layout.isAncestor(a, of: b)", "true"),
    Mutant("containsedge", "Tree.swift", "a != b && (nodes[a].parent == b || nodes[b].parent == a)", "nodes[a].parent == b || nodes[b].parent == a"),
    Mutant("arbsource", "Arborescence.swift", "DirectedEdge(from: _layout.vertices[_layout.nodes[c].parent], to: _layout.vertices[c])", "DirectedEdge(from: _layout.vertices[c], to: _layout.vertices[_layout.nodes[c].parent])"),

    # Equality and hashing
    Mutant("equalroot", "RootedTree.swift", "lhs.root == rhs.root && lhs._layout.sameGraph(as: rhs._layout)", "lhs._layout.sameGraph(as: rhs._layout)"),
    Mutant("equaledges", "Tree.swift", "                guard other.nodes[a].parent == b || other.nodes[b].parent == a else { return false }", "", mode="stmt", nth=0),
    Mutant("hashedges", "Tree.swift", "        hasher.combine(edgeHashes)", "", mode="stmt"),

    # Forest
    Mutant("treelocal", "Forest.swift", "ends.append(_localIndex[_layout.ends[2 * e + 1]])", "ends.append(_localIndex[_layout.ends[2 * e]])"),
    Mutant("forestsingle", "Forest.swift", "_layout.roots.count == 1", "_layout.roots.count <= 1"),

    # Prüfer
    Mutant("pruferleaf", "Prufer.swift", "next < pointer", "next <= pointer"),
    Mutant("pruferdecode", "Prufer.swift", "v < pointer", "true"),
    Mutant("prufermin", "Prufer.swift", "n >= 2", "n >= 3"),
    Mutant("pruferrange", "Prufer.swift", "x < n", "true"),

    # Input
    Mutant("orient", "TreeLayout.swift", "edge.u != vertices[ends[2 * e]]", "false"),
    Mutant("firstappear", "TreeLayout.swift", "b == count", "false"),
    Mutant("firstrange", "TreeLayout.swift", "UInt(bitPattern: a) >= UInt(bitPattern: count)", "false"),
    Mutant("smalllookup", "TreeLayout.swift", "vertices.firstIndex(of: vertex)", "vertices.isEmpty ? nil : 0"),
    Mutant("singletree", "Forest.swift", "_vertexStart[t + 1] - _vertexStart[t] == 1", "_vertexStart[t + 1] - _vertexStart[t] <= 2"),
    Mutant("pruferxor", "Prufer.swift", "            xor[next] ^= leaf", "", mode="stmt"),
]
