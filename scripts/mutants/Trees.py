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
#   algobspine              Algorithm B's links are labels of non-root vertices, never 1.
#   huffmanorder            the standard library's sort keeps equal weights in offset order anyway.
#   prefixrange             the array read past the end traps as the precondition does.
#   parentskip              skipping the parent vertex instead of its edge still finds a parallel
#                           pair, from the parent's row.

TESTS = ["TreesTests"]

MUTANTS = [
    # Validation
    Mutant("edgecount", "TreeLayout.swift", "m == n - 1", "m <= n - 1", nth=0),
    Mutant("forestcount", "TreeLayout.swift", "m <= max(n - 1, 0)", "m <= n"),
    Mutant("cycle", "TreeLayout.swift", "                                                guard !reached[w] else { return false }", "                                                guard !reached[w] else { continue }", mode="stmt"),
    Mutant("parentskip", "TreeLayout.swift", "e == nodes[v].parentEdge", "rowNeighbors[k] == nodes[v].parent"),
    Mutant("orientation", "TreeLayout.swift", "                                                if oriented, ends[2 &* e] != v { return false }", "", mode="stmt"),
    Mutant("reachall", "TreeLayout.swift", "count == n", "true"),
    Mutant("endrange", "TreeLayout.swift", "                    guard UInt(bitPattern: x) < UInt(bitPattern: n) else { return false }", "", mode="stmt"),
    Mutant("oneincoming", "Arborescence.swift", "            if incoming[t] > 1 { return nil }", "", mode="stmt"),
    Mutant("tworoots", "RootedTree.swift", "                guard root < 0 else { return nil }", "", mode="stmt"),
    Mutant("selfparent", "RootedTree.swift", "                guard p != v else { return nil }", "", mode="stmt"),
    Mutant("parentrange", "RootedTree.swift", "            guard p >= 0, p < n else { return nil }", "            guard p < n else { return nil }", mode="stmt"),
    Mutant("istreecount", "Recognition.swift", "edgeCount == n - 1", "edgeCount <= n - 1", nth=0),
    Mutant("treereach", "Recognition.swift", "reached == n", "true", nth=0),
    Mutant("arbreach", "Recognition.swift", "reached == n", "true", nth=1),

    # The rooting
    Mutant("twin", "TreeLayout.swift", "twin[k]", "(twin[k] == 0 ? 0 : twin[k] - 1)"),
    Mutant("sizes", "TreeLayout.swift", "                                                    if p >= 0 { nodes[p].size &+= nodes[v].size }", "", mode="stmt"),
    Mutant("height", "TreeLayout.swift", "                if depth > height { height = depth }", "", mode="stmt"),
    Mutant("component", "TreeLayout.swift", "roots.count", "0", nth=0),
    Mutant("rootfirst", "TreeLayout.swift", "reached[next]", "(reached[next] && nodes[next].depth > 0)"),
    Mutant("reroot", "TreeLayout.swift", "roots[0] == root", "true"),

    # Queries
    Mutant("ancestorstrict", "TreeLayout.swift", "pa < pb && pb < pa + nodes[a].size", "pa <= pb && pb < pa + nodes[a].size"),
    Mutant("postorder", "RootedTree.swift", "node.preorderPosition + node.size - 1 - node.depth", "node.preorderPosition + node.size - 1 - (node.depth == 0 ? 0 : 1)"),
    Mutant("descendants", "RootedTree.swift", "(start + 1) ..< (start + nodes[v].size)", "start ..< (start + nodes[v].size)"),
    Mutant("childhole", "RootedTree.swift", "position < _hole ? position : position + 1", "position <= _hole ? position : position + 1"),
    Mutant("pathorder", "TreeLayout.swift", "up.append(contentsOf: down.dropLast().reversed())", "up.append(contentsOf: down.dropLast())"),
    Mutant("pathcomponent", "TreeLayout.swift", "        guard nodes[a].component == nodes[b].component else { return nil }", "", mode="stmt"),
    Mutant("arbpath", "Arborescence.swift", "a == b || _layout.isAncestor(a, of: b)", "true", nth=0),
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
    Mutant("pruferbyindex", "Prufer.swift", "Self._rangeValues(layout.vertices)", "nil"),
    Mutant("pruferrangecheck", "Prufer.swift", "UInt(bitPattern: x) >= count", "false"),
    Mutant("pruferrangeint", "Prufer.swift", "        guard Vertex.self == Int.self else { return nil }", "", mode="stmt"),
    Mutant("pruferrankdegree", "Prufer.swift", "degree[x] = layout.rowOffsets[v + 1] - layout.rowOffsets[v]", "degree[v] = layout.rowOffsets[v + 1] - layout.rowOffsets[v]"),
    Mutant("pruferrankxor", "Prufer.swift", "xor[x] ^= values[layout.rowNeighbors[k]]", "xor[x] ^= layout.rowNeighbors[k]"),
    Mutant("pruferranknames", "Prufer.swift", "unsafeBitCast(ContiguousArray(0 ..< n), to: ContiguousArray<Vertex>.self)", "layout.vertices"),

    # Input
    Mutant("orient", "TreeLayout.swift", "edge.u != vertices[ends[2 * e]]", "false"),
    Mutant("firstappear", "TreeLayout.swift", "b == count", "false"),
    Mutant("firstrange", "TreeLayout.swift", "UInt(bitPattern: a) >= UInt(bitPattern: count)", "false"),
    Mutant("smalllookup", "TreeLayout.swift", "vertices.firstIndex(of: vertex)", "vertices.isEmpty ? nil : 0"),
    Mutant("singletree", "Forest.swift", "_vertexStart[t + 1] - _vertexStart[t] == 1", "_vertexStart[t + 1] - _vertexStart[t] <= 2"),
    Mutant("pruferxor", "Prufer.swift", "            xor[next] ^= leaf", "", mode="stmt"),

    # The checked: spellings (§L): the one lookup that throws, and each spelling's own reading.
    Mutant("checkednumber", "TreeLayout.swift", "Self.lookup(vertex, vertices, slots, dense)", "Self.lookup(vertex, vertices, slots, dense) ?? 0", nth=1),
    Mutant("treeneighbors", "Tree.swift", "_layout.rowNeighbors[_layout.row(v)]", "_layout.rowEdges[_layout.row(v)]"),
    Mutant("treepath", "Tree.swift", "_layout._path(a, b)!", "_layout._path(b, a)!"),
    Mutant("rootedparent", "RootedTree.swift", "p < 0 ? nil : _layout.vertices[p]", "_layout.vertices[max(p, 0)]", nth=1),
    Mutant("rootedparentedge", "RootedTree.swift", "e < 0 ? nil : e", "e", nth=1),
    Mutant("rootedancestor", "RootedTree.swift", "_layout.isAncestor(x, of: y)", "_layout.isAncestor(y, of: x)"),
    Mutant("rootedpath", "RootedTree.swift", "_layout._path(a, b)!", "_layout._path(b, a)!"),
    Mutant("rootedneighbors", "RootedTree.swift", "_layout.rowNeighbors[_layout.row(v)]", "_layout.rowEdges[_layout.row(v)]"),
    Mutant("forestpath", "Forest.swift", "_layout._path(a, b)", "_layout._path(b, a)"),
    Mutant("forestneighbors", "Forest.swift", "_layout.rowNeighbors[_layout.row(v)]", "_layout.rowEdges[_layout.row(v)]"),
    Mutant("arbparent", "Arborescence.swift", "p < 0 ? nil : _layout.vertices[p]", "_layout.vertices[max(p, 0)]", nth=2),
    Mutant("arbparentedge", "Arborescence.swift", "e < 0 ? nil : e", "e", nth=1),
    Mutant("arbancestor", "Arborescence.swift", "_layout.isAncestor(x, of: y)", "_layout.isAncestor(y, of: x)"),
    Mutant("arbpathdown", "Arborescence.swift", "a == b || _layout.isAncestor(a, of: b)", "true", nth=1),
    Mutant("arbpredecessor", "Arborescence.swift", "Predecessors(p < 0 ? nil : _layout.vertices[p])", "Predecessors(_layout.vertices[max(p, 0)])", nth=1),
    Mutant("arbdegree", "Arborescence.swift", "outDegree(ofIndex: v) + inDegree(ofIndex: v)", "outDegree(ofIndex: v)"),
    Mutant("arbsourcelow", "Arborescence.swift", "        guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }\n        return _layout.vertices[_layout.nodes[_layout.child(ofEdge: position)].parent]", "        guard position < _layout.edgeCount else { throw EdgeNotFound() }\n        return _layout.vertices[_layout.nodes[_layout.child(ofEdge: position)].parent]", mode="stmt"),
    Mutant("arbtargethigh", "Arborescence.swift", "        guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }\n        return _layout.vertices[_layout.child(ofEdge: position)]", "        guard position >= 0 && position <= _layout.edgeCount else { throw EdgeNotFound() }\n        return _layout.vertices[_layout.child(ofEdge: position)]", mode="stmt"),
]

# Attached maps and generations (PropertyGraph.swift, one block per type in the order Tree,
# RootedTree, Arborescence, Forest; the stamps in each type's file). The trapping subscripts' range
# preconditions get no mutants: the dense storage's own array read traps at the same positions, so
# removing one changes only the message. Nor does an edge map sized by the vertex count: a tree or
# forest has fewer edges than vertices, so the extra value is never read.
M = "PropertyGraph.swift"
for k, name in enumerate(["tree", "rooted", "arborescence", "forest"]):
    MUTANTS += [
        Mutant(f"map{name}checkededge", M, "guard position >= 0 && position < _layout.edgeCount else { throw EdgeNotFound() }", "", mode="stmt", nth=k),
        Mutant(f"map{name}checkedvertex", M, "guard position >= 0 && position < _layout.count else { throw VertexNotFound() }", "", mode="stmt", nth=k),
        # Occurrence 4k of `_layout.count` is the block's `addVertexMap` size.
        Mutant(f"map{name}vertexcount", M, "_layout.count", "_layout.edgeCount", nth=4 * k),
    ]
for file, name in [("Tree.swift", "tree"), ("RootedTree.swift", "rooted"), ("Arborescence.swift", "arborescence"), ("Forest.swift", "forest")]:
    MUTANTS.append(Mutant(f"{name}stamp", file, "        _generation.stamp()", "", mode="stmt"))

# OrderedTree
O = "OrderedTree.swift"
MUTANTS += [
    Mutant("orderedrepeat", O, "slots.updateValue(vertices.count, forKey: child) == nil", "true"),
    Mutant("orderedrange", O, "UInt(bitPattern: x) < UInt(bitPattern: n)", "UInt(bitPattern: x) <= UInt(bitPattern: n)"),
    Mutant("orderedroot", O, "dense ? ends.first ?? 0 : 0", "0"),
    Mutant("orderedsamecount", O, "rowLength(a) == other.rowLength(b)", "true"),
    Mutant("orderedsamevertex", O, "vertices[a] == other.vertices[b]", "true"),
    Mutant("orderedhashcount", O, "            hasher.combine(rowLength(v))", "", mode="stmt"),
    Mutant("ordereddeeper", O, "d > previous", "d >= previous"),
    Mutant("orderedclose", O, "String(repeating: \")\", count: previous - d)", "String(repeating: \")\", count: 0)"),
]

# BinaryTree
B = "BinaryTree.swift"
MUTANTS += [
    Mutant("binaryleftrepeat", B, "guard slots.updateValue(vertices.count, forKey: left) == nil else { return nil }", "slots[left] = vertices.count", mode="stmt"),
    Mutant("binaryrightrepeat", B, "guard slots.updateValue(vertices.count, forKey: right) == nil else { return nil }", "slots[right] = vertices.count", mode="stmt"),
    Mutant("binaryrightside", B, "side |= 2", "side = 2", mode="stmt"),
    Mutant("binaryrenumber", B, "renumbered[numbers[i]] = side", "renumbered[i] = side", mode="stmt"),
    Mutant("binaryhole", B, "hole >= 0 && hole <= j", "hole >= 0 && hole < j"),
    Mutant("binaryrightslot", B, "_child(v, Int(_sides[v] & 1))", "_child(v, 0)"),
    Mutant("binaryinorderright", B, "            v = _right(top)", "            v = -1", mode="stmt"),
    Mutant("binaryequalsides", B, "lhs._sides[lhs._layout.preorder[i]] != rhs._sides[rhs._layout.preorder[i]]", "false"),
    Mutant("binaryhashsides", B, "        for v in _layout.preorder { hasher.combine(_sides[v]) }", "", mode="stmt"),
    Mutant("algobreset", B, "_left[j] = j + 1", "_left[j] = 0", mode="stmt"),
    Mutant("algobspine", B, "_right[y] > 0", "_right[y] > 1"),
    Mutant("algobpromote", B, "if k > 0 { _right[k] = 0 } else { _left[j] = 0 }", "if k > 0 { _right[k] = 0 }", mode="stmt"),
    Mutant("algobsplice", B, "_right[y] = _right[j]", "_right[y] = 0", mode="stmt"),
    Mutant("algobstart", B, "_done = n == 0", "_done = n <= 1", mode="stmt"),
    Mutant("huffmantie", B, "weight[leaves[head]] <= joined[joinedHead]", "weight[leaves[head]] < joined[joinedHead]"),
    Mutant("huffmanorder", B, "(weight[$0] == weight[$1] && $0 < $1)", "false"),
    Mutant("huffmanedges", B, "ends[2 * e + 1] = children[2 * t]", "ends[2 * e + 1] = children[2 * t + 1]", mode="stmt"),
    Mutant("huffmansides", B, "for v in n ..< count { sides[v] = 3 }", "for v in n ..< count { sides[v] = 1 }", mode="stmt"),
    Mutant("binarytruncate", B, "for t in stack.reversed() where t == -1 { text += \")\" }", "", mode="stmt"),
]

# Prefix trees
P = "PrefixTree.swift"
MUTANTS += [
    Mutant("prefixfollow", P, "v = w", "v = 0", mode="stmt", nth=0),
    Mutant("prefixnew", P, "child[key] = w", "child[_PrefixTreeKey(0, symbol)] = w", mode="stmt"),
    Mutant("prefixend", P, "for v in ends { isEnd[v] = true }", "for v in ends.dropLast() { isEnd[v] = true }", mode="stmt"),
    Mutant("prefixrange", P, "position < _symbols.count", "position <= _symbols.count", nth=0),
    Mutant("prefixcheckedrange", P, "guard position >= 0 && position < _symbols.count else { throw EdgeNotFound() }", "guard position < _symbols.count else { throw EdgeNotFound() }", mode="stmt"),
    Mutant("prefixendrange", P, "guard vertex >= 0 && vertex < _isEnd.count else { throw VertexNotFound() }", "guard vertex < _isEnd.count else { throw VertexNotFound() }", mode="stmt"),
    Mutant("prefixequal", P, "lhs.sequenceEnds == rhs.sequenceEnds", "true"),
]
