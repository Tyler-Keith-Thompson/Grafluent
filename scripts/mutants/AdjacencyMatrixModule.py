# Planted bugs for AdjacencyMatrixModule's `checked:` spellings (README Principle 6): the range
# guard of each row lookup, the cell guard of the checked edge endpoints, the endpoints checked by
# `insert(checked:)`, and each twin calling its own trapping spelling. Run with
# `just mutate AdjacencyMatrixModule`. See scripts/mutate.py.
#
# Attached maps and generations: the Szudzik offsets, every reset of a removed edge's cells, the
# defaults appended with a vertex, the maps kept through `removeAll` and `removeAllEdges`, the
# complement's fresh maps, the subscripts' liveness checks, and every generation advance.
#
# The rest of the matrix predates the mutation suite and has no mutants here yet.
#
# Known equivalent mutants (they survive by design): none.
#
# Not planted, as equivalent: `insertEdges` advancing per cell instead of once (more versions, the
# same answers), a new lineage starting at another version, the stamp forgetting no address on a
# move it already mismatches, and the cleared matrices keeping the old stamp's slots (the new
# buffer's address never matches them).
#
# Removed as dead code after planting: the vertex maps' range checks in the subscripts (each map
# holds exactly one value per vertex, so its own bounds check traps on the same positions).

TESTS = ["AdjacencyMatrixTests"]

M = "AdjacencyMatrix.swift"
P = "AdjacencyMatrix+PropertyGraph.swift"

ROW_GUARD = "guard contains(vertex) else { throw VertexNotFound() }"
EDGE_GUARD = "guard contains(edge: DirectedEdge(from: position.source, to: position.target)) else { throw EdgeNotFound() }"

MUTANTS = [
    # Each row lookup's range guard, in file order. Without it, -1 and n reach the trapping
    # spelling and the process traps instead of throwing.
    Mutant("successorsguard", M, ROW_GUARD, "", mode="stmt", nth=0),
    Mutant("predecessorsguard", M, ROW_GUARD, "", mode="stmt", nth=1),
    Mutant("outedgesguard", M, ROW_GUARD, "", mode="stmt", nth=2),
    Mutant("inedgesguard", M, ROW_GUARD, "", mode="stmt", nth=3),
    Mutant("outdegreeguard", M, ROW_GUARD, "", mode="stmt", nth=4),
    Mutant("indegreeguard", M, ROW_GUARD, "", mode="stmt", nth=5),
    Mutant("degreeguard", M, ROW_GUARD, "", mode="stmt", nth=6),
    Mutant("vertexindexguard", M, ROW_GUARD, "", mode="stmt", nth=7),

    # Each twin reads its own row.
    Mutant("predecessorsrow", M, "return predecessors(of: vertex)", "return successors(of: vertex)", mode="stmt"),
    Mutant("inedgesrow", M, "return inEdges(of: vertex)", "return outEdges(of: vertex)", mode="stmt"),
    Mutant("indegreerow", M, "return inDegree(of: vertex)", "return outDegree(of: vertex)", mode="stmt"),
    Mutant("degreerow", M, "return degree(of: vertex)", "return outDegree(of: vertex)", mode="stmt"),

    # The checked endpoints: the cell guard, and each its own end.
    Mutant("sourceguard", M, EDGE_GUARD, "", mode="stmt", nth=0),
    Mutant("targetguard", M, EDGE_GUARD, "", mode="stmt", nth=1),
    Mutant("sourceend", M, "return source(ofEdgeAt: position)", "return target(ofEdgeAt: position)", mode="stmt"),
    Mutant("targetend", M, "return target(ofEdgeAt: position)", "return source(ofEdgeAt: position)", mode="stmt", nth=1),

    # insert(checked:) checks both endpoints and then inserts as insert(edge:) does.
    Mutant("insertsourceonly", M, "guard contains(edge.source), contains(edge.target) else { throw VertexNotFound() }", "guard contains(edge.source) else { throw VertexNotFound() }", mode="stmt"),
    Mutant("inserttargetonly", M, "guard contains(edge.source), contains(edge.target) else { throw VertexNotFound() }", "guard contains(edge.target) else { throw VertexNotFound() }", mode="stmt"),
    Mutant("insertresult", M, "return insert(edge: edge)", "_ = insert(edge: edge); return (true, edge)", mode="stmt"),

    # Attached maps (AdjacencyMatrix+PropertyGraph.swift and the maintenance in AdjacencyMatrix.swift).
    Mutant("szudzikorder", P, "source < target ? target &* target &+ source : source &* source &+ source &+ target", "source <= target ? target &* target &+ source : source &* source &+ source &+ target"),
    Mutant("szudzikupper", P, "source < target ? target &* target &+ source : source &* source &+ source &+ target", "source < target ? target &* target &+ source : source &* source &+ target"),
    Mutant("mapcells", P, "_edgeMaps.add(default: value, layout: .dense, count: _vertexCount &* _vertexCount)", "_edgeMaps.add(default: value, layout: .dense, count: _vertexCount)"),
    Mutant("mapvertices", P, "_vertexMaps.add(default: value, layout: .dense, count: _vertexCount)", "_vertexMaps.add(default: value, layout: .dense, count: 0)"),
    Mutant("edgegetcheck", P, "            _checkEdge(at: position)", "", mode="stmt", nth=0),
    Mutant("edgesetcheck", P, "            _checkEdge(at: position)", "", mode="stmt", nth=1),
    Mutant("checkededge", P, "guard contains(edge: DirectedEdge(from: position.source, to: position.target)) else { throw EdgeNotFound() }", "", mode="stmt"),
    Mutant("checkedvertex", P, "guard contains(position) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("cellreset", M, "        if !value, !_edgeMaps.isEmpty { _edgeMaps.reset(at: Self._edgeMapOffset(source, target)) }", "", mode="stmt"),
    Mutant("rowreset", M, "        if !_edgeMaps.isEmpty { _resetEdgeMaps(ofRow: vertex) }", "", mode="stmt"),
    Mutant("columnreset", M, "        if !_edgeMaps.isEmpty { _resetEdgeMaps(ofColumn: vertex) }", "", mode="stmt"),
    Mutant("combinereset", M, "        if let before { _resetEdgeMaps(removedSince: before) }", "", mode="stmt"),
    Mutant("combinecleared", M, "before[index] & ~_words[index]", "before[index]"),
    Mutant("resetcolumn", M, "word &* UInt.bitWidth &+ bits.trailingZeroBitCount", "bits.trailingZeroBitCount"),
    Mutant("appendcells", M, "_edgeMaps.appendDefaults(count: 2 &* vertex &+ 1)", "_edgeMaps.appendDefaults(count: 2 &* vertex)"),
    Mutant("appendvertexmaps", M, "        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaults(count: 1) }", "", mode="stmt"),
    Mutant("removealledgesmaps", M, "            _edgeMaps.removeAll(keepingCapacity: keepingCapacity)\n            _edgeMaps.appendDefaults(count: n &* n)", "", mode="stmt"),
    Mutant("removeallcells", M, "_edgeMaps.appendDefaults(count: n &* n)", "_edgeMaps.appendDefaults(count: n)"),
    Mutant("removeallvertexmaps", M, "        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("removealledgemaps", M, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("complementedgemaps", M, "        result._edgeMaps = _AttachedMaps()", "", mode="stmt"),
    Mutant("complementvertexmaps", M, "        result._vertexMaps = _AttachedMaps()", "", mode="stmt"),

    # Generations: each structural mutation advances, a call that changes nothing does not.
    Mutant("gencombine", M, "        _advanceGeneration()", "", mode="stmt", nth=0),
    Mutant("genrowclear", M, "        _advanceGeneration()", "", mode="stmt", nth=1),
    Mutant("gencolumnclear", M, "        _advanceGeneration()", "", mode="stmt", nth=2),
    Mutant("genappend", M, "        _advanceGeneration()", "", mode="stmt", nth=3),
    Mutant("genremovealledges", M, "        _advanceGeneration()", "", mode="stmt", nth=4),
    Mutant("genremoveall", M, "        _advanceGeneration()", "", mode="stmt", nth=5),
    # A cell write (insert, remove, the subscript) advances, and insertEdges once for many.
    Mutant("gensetcell", M, "        if advancing { Self._advanceGeneration(in: degrees) }", "", mode="stmt"),
    Mutant("geninsertedges", M, "        if inserted > 0 { _advanceGeneration() }", "        _advanceGeneration()", mode="stmt"),
    Mutant("geninsertedgesnone", M, "        if inserted > 0 { _advanceGeneration() }", "        if inserted > 1 { _advanceGeneration() }", mode="stmt"),
    # The stamp in `_degrees`: a moved buffer starts a lineage, a write in place is a version.
    Mutant("stampmoved", M, "if _slowPath(degrees[3] != Int(bitPattern: degrees)) { _startLineage(in: degrees) }", "if false { _startLineage(in: degrees) }", mode="stmt"),
    Mutant("stampversion", M, "        degrees[1] &+= 1", "", mode="stmt"),
    Mutant("stamplineage", M, "        degrees[2] = Int(truncatingIfNeeded: _GenerationStamp._newLineage())", "", mode="stmt"),
    Mutant("complementstamp", M, "        result._degrees[2] = 0", "", mode="stmt"),
    # The degrees and the edge count in `_degrees`.
    Mutant("edgecountslot", M, "        _degrees[0] &+= change", "", mode="stmt"),
    Mutant("insamesasout", M, "        degrees[_inSlot(target)] &+= change", "        degrees[Self._outSlot(target)] &+= change", mode="stmt"),
    Mutant("restrideindegrees", M, "            degrees[inBase &+ vertex] = _degree(at: _inSlot(vertex))", "", mode="stmt"),
    Mutant("restrideedgecount", M, "        degrees[0] = _edgeCount", "", mode="stmt"),
    Mutant("transposeddegrees", M, "            result._degrees[result._inSlot(vertex)] = _degree(at: Self._outSlot(vertex))", "            result._degrees[result._inSlot(vertex)] = _degree(at: _inSlot(vertex))", mode="stmt"),
    Mutant("removealledgeskeepdegrees", M, "            for slot in Self._headerCount ..< _degrees.count { _degrees[slot] = 0 }\n            _edgeCount = 0", "            _edgeCount = 0", mode="stmt", nth=0),
    Mutant("removeallkeepdegrees", M, "            for slot in Self._headerCount ..< _degrees.count { _degrees[slot] = 0 }\n            _edgeCount = 0", "            _edgeCount = 0", mode="stmt", nth=1),
]
