# Planted bugs for BipartiteGraphs; run with `just mutate BipartiteGraphs`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   loopcycle       the self-loop shortcut: the general path closes the same one-vertex cycle
#                   ([v] and [e]: the climb stops at once, and w's list drops to nothing).
#   projectiononce  the skip of pairs already found from their earlier end: the second insertion
#                   of a pair is refused as a repeat, so the output is the same, found twice.
#   (not planted) `other > k` as `other >= k` in the weighted projections: x is never u, so
#                   `other == k` cannot occur.

TESTS = ["BipartiteGraphsTests"]

MUTANTS = [
    # Two-colouring and the odd cycle
    Mutant("conflict", "Recognition.swift", "far == near", "false"),
    Mutant("alternate", "Recognition.swift", "side[w] = 1 - near", "side[w] = near", mode="stmt"),
    Mutant("rootside", "Recognition.swift", "side[root] = 0", "side[root] = 1", mode="stmt"),
    Mutant("loopcycle", "Recognition.swift", "guard v != w else { return ([v], [e]) }", "", mode="stmt"),
    Mutant("cycleedge", "Recognition.swift", "Array(upEdges.reversed()) + [e] + downEdges", "Array(upEdges.reversed()) + downEdges + [e]"),
    Mutant("rotate", "Cycle.swift", "for i in 1 ..< max(n, 1) where vertices[i] < vertices[r] { r = i }", "", mode="stmt", module="Walks"),
    Mutant("turn", "Cycle.swift", "guard undirected, n >= 2, es[n - 1] < es[0] else { return (vs, es) }", "return (vs, es)", mode="stmt", module="Walks"),
    Mutant("leftfirst", "Recognition.swift", "for v in sides.indices where sides[v] == 0 { members.append(listed?[v] ?? graph.vertex(atIndex: v)) }", "", mode="stmt"),

    # BipartiteGraph
    Mutant("fastpath", "BipartiteGraph.swift", "list._reverseEdge(at: position)", "", mode="stmt"),
    Mutant("overlap", "BipartiteGraph.swift", "                if _side[slot] == .left { return nil }", "", mode="stmt"),
    Mutant("edgeside", "BipartiteGraph.swift", "_side[u] != _side[v]", "true", nth=0),
    Mutant("othersidecheck", "BipartiteGraph.swift", "            guard _side[slot] == side else { throw .onOtherSide(_side[slot]) }", "", mode="stmt"),
    Mutant("othersidecase", "BipartiteGraph.swift", ".onOtherSide(_side[slot])", ".onOtherSide(side)", nth=0),
    Mutant("insertsameside", "BipartiteGraph.swift", "        guard _side[u] != _side[v] else { throw .sameSide(_side[u]) }", "", mode="stmt", nth=0),
    Mutant("checkedsameside", "BipartiteGraph.swift", "        guard _side[u] != _side[v] else { throw .sameSide(_side[u]) }", "", mode="stmt", nth=1),
    Mutant("samesidecase", "BipartiteGraph.swift", ".sameSide(_side[u])", ".sameSide(.left)", nth=0),
    Mutant("checkedsamesidecase", "BipartiteGraph.swift", ".sameSide(_side[u])", ".sameSide(.left)", nth=1),
    Mutant("checkedmissing", "BipartiteGraph.swift", "            throw .missingEndpoint", "            throw .sameSide(.left)", mode="stmt"),
    Mutant("orientation", "BipartiteGraph.swift", "_side[u] == .left ? _base._insertEdge(slots: u, v) : _base._insertEdge(slots: v, u)", "_base._insertEdge(slots: u, v)"),
    Mutant("sidelistswap", "BipartiteGraph.swift", "                _left[offset] = moved", "", mode="stmt"),
    Mutant("sideoffset", "BipartiteGraph.swift", "                _sideOffset[moved] = offset", "", mode="stmt", nth=0),
    Mutant("renameslot", "BipartiteGraph.swift", "            _side[slot] = _side[last]", "", mode="stmt"),
    Mutant("renamelist", "BipartiteGraph.swift", "if _side[slot] == .left { _left[_sideOffset[slot]] = slot } else { _right[_sideOffset[slot]] = slot }", "", mode="stmt"),
    Mutant("nodeset", "BipartiteGraph.swift", "guard leftSet.contains(edge.u) != leftSet.contains(edge.v) else { return nil }", "", mode="stmt"),
    Mutant("nonvertexleft", "BipartiteGraph.swift", "            guard graph.contains(v) else { return nil }", "", mode="stmt"),
    Mutant("equalsides", "BipartiteGraph.swift", "for slot in lhs._left where rhs._side[rhs._base.vertexIndex(of: lhs._base.vertex(atIndex: slot))] != .left { return false }", "", mode="stmt"),
    Mutant("hashsides", "BipartiteGraph.swift", "        hasher.combine(leftHashes)", "", mode="stmt"),
    Mutant("projectionself", "BipartiteGraph.swift", "x == u || lastSeen[x] == u", "lastSeen[x] == u"),
    Mutant("projectiononce", "BipartiteGraph.swift", "if other < k { continue }", "", mode="stmt"),
    Mutant("decodeinside", "BipartiteGraph.swift", "(pairs[i] < leftVertices.count) != (pairs[i + 1] < leftVertices.count)", "true"),
    Mutant("encodeoffset", "BipartiteGraph.swift", "pairs.append(_left.count + _sideOffset[v])", "pairs.append(_sideOffset[v])", mode="stmt"),
    Mutant("equalfast", "BipartiteGraph.swift", "lhs._side == rhs._side", "lhs._left.count == rhs._left.count"),

    # The checked: lookups
    Mutant("checkedside", "BipartiteGraph.swift", "_base._slotIfPresent(of: vertex)", "Optional(_base._slotIfPresent(of: vertex) ?? 0)", nth=3),
    Mutant("checkedsidevalue", "BipartiteGraph.swift", "return _side[slot]", "return .left", nth=1, mode="stmt"),
    Mutant("checkedneighbors", "BipartiteGraph.swift", "        try _base.neighbors(checked: vertex)", "        _base.neighbors(of: vertex)", mode="stmt"),
    Mutant("checkedincident", "BipartiteGraph.swift", "        try _base.incidentEdges(checked: vertex)", "        _base.incidentEdges(of: vertex)", mode="stmt"),
    Mutant("checkeddegree", "BipartiteGraph.swift", "        try _base.degree(checked: vertex)", "        _base.degree(of: vertex)", mode="stmt"),
    Mutant("checkedindex", "BipartiteGraph.swift", "        try _base.vertexIndex(checked: vertex)", "        _base.vertexIndex(of: vertex)", mode="stmt"),

    # Forwarding to the base: generation and attached maps
    Mutant("generation", "BipartiteGraph.swift", "_base.generation", "GraphGeneration.untracked"),
    Mutant("mapsetedge", "BipartiteGraph.swift", "_base[map, ofEdgeAt: position] = newValue", "", mode="stmt"),
    Mutant("mapsetslot", "BipartiteGraph.swift", "_base[map, ofVertexAt: position] = newValue", "", mode="stmt"),
    Mutant("mapsetvertex", "BipartiteGraph.swift", "_base[map, of: vertex] = newValue", "", mode="stmt"),
    Mutant("mapcheckededge", "BipartiteGraph.swift", "try _base[map, checkedEdgeAt: position]", "_base[map, ofEdgeAt: position]", mode="stmt"),
    Mutant("mapcheckedslot", "BipartiteGraph.swift", "try _base[map, checkedVertexAt: position]", "_base[map, ofVertexAt: position]", mode="stmt"),
    Mutant("mapcheckedvertex", "BipartiteGraph.swift", "try _base[map, checked: vertex]", "_base[map, of: vertex]", mode="stmt"),

    # Bipartition.side(checked:)
    Mutant("ckbipartitionlookup", "Recognition.swift", "_numbers[vertex]", "Optional(_numbers[vertex] ?? 0)", nth=1),
    Mutant("ckbipartitionvalue", "Recognition.swift", "return _sides[v]", "return .left", mode="stmt", nth=1),
    Mutant("ckbipartitionguard", "Recognition.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("ckbipartitionthrow", "Recognition.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt"),

    # Weighted projections
    Mutant("wpfirstmet", "WeightedProjection.swift", "if shared[x] == 0 { touched.append(x) }", "touched.append(x)", mode="stmt"),
    Mutant("wpcount", "WeightedProjection.swift", "shared[x] &+= 1", "shared[x] = 1", mode="stmt"),
    Mutant("wpearlier", "WeightedProjection.swift", "other > k", "true"),
    Mutant("wpreset", "WeightedProjection.swift", "shared[x] = 0", "", mode="stmt"),
    Mutant("wpsumreset", "WeightedProjection.swift", "if collaboration { sums[x] = 0 }", "", mode="stmt"),
    Mutant("wpshare", "WeightedProjection.swift", "1 / Double(dw &- 1)", "1 / Double(dw)"),
    Mutant("wpxdegree", "WeightedProjection.swift", "_base.degree(ofIndex: x)", "du"),
    Mutant("wpjaccard", "WeightedProjection.swift", "du &+ dx &- shared", "du &+ dx"),
    Mutant("wplesser", "WeightedProjection.swift", "Swift.min(du, dx)", "Swift.max(du, dx)"),
    Mutant("wpwrite", "WeightedProjection.swift", "for p in values.indices { result[map, ofEdgeAt: p] = values[p] }", "", mode="stmt"),
]
