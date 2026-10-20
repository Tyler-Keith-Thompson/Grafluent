# Planted bugs for CompressedSparseRowModule's `checked:` spellings: the range
# guard of each row lookup and of the checked edge endpoints, and each twin calling its own
# trapping spelling. Run with `just mutate CompressedSparseRowModule`. See scripts/mutate.py.
#
# The rest of the row form has no mutants; the column form (BidirectionalCompressedSparseRow)
# has its sources, positions, guards and degrees.
#
# Known equivalent mutants (they survive by design): dropping the column form's range guards in
# predecessors(of:), inEdges(of:) and inDegree(of:), whose slice index then traps on the same
# vertex with a worse message.

TESTS = ["CompressedSparseRowTests"]

C = "CompressedSparseRow.swift"

ROW_GUARD = "guard contains(vertex) else { throw VertexNotFound() }"
EDGE_GUARD = "guard edgeIndex >= 0 && edgeIndex < edgeCount else { throw EdgeNotFound() }"

B = "BidirectionalCompressedSparseRow.swift"

MUTANTS = [
    # The column form: its sources, its positions, its guards and its degrees.
    Mutant("bidisources", B, "_inSources = column._targets", "_inSources = column._offsets", mode="stmt"),
    Mutant("bidipositions", B, "_inPositions = positions", "_inPositions = Array(0 ..< positions.count)", mode="stmt"),
    Mutant("bidiindegree", B, "_inOffsets[vertex &+ 1] &- _inOffsets[vertex]", "_inOffsets[vertex &+ 1]"),
    Mutant("bididegree", B, "outDegree(of: vertex) &+ inDegree(of: vertex)", "outDegree(of: vertex)"),
    Mutant("bidiforeach", B, "for v in predecessors(of: index) { body(v) }", "", mode="stmt"),
    Mutant("biditransposed", B, "CompressedSparseRow(_offsets: _inOffsets, _targets: _inSources)", "_base"),
    Mutant("bidicheckedpred", B, "guard UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("bidicheckedinedges", B, "guard UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount) else { throw VertexNotFound() }", "", mode="stmt", nth=1),
    Mutant("bidicheckedindegree", B, "guard UInt(bitPattern: vertex) < UInt(bitPattern: vertexCount) else { throw VertexNotFound() }", "", mode="stmt", nth=2),
    Mutant("bidiequal", B, "lhs._base == rhs._base", "lhs._base.vertexCount == rhs._base.vertexCount"),
    Mutant("bidimapwrite", B, "_base[map, ofEdgeAt: position] = newValue", "_ = newValue", mode="stmt"),
    # Each row lookup's range guard, in file order.
    Mutant("successorsguard", C, ROW_GUARD, "", mode="stmt", nth=0),
    Mutant("outedgesguard", C, ROW_GUARD, "", mode="stmt", nth=1),
    Mutant("outdegreeguard", C, ROW_GUARD, "", mode="stmt", nth=2),
    Mutant("vertexindexguard", C, ROW_GUARD, "", mode="stmt", nth=3),

    # The edge-index guard: removed, and each bound moved by one.
    Mutant("sourceguard", C, EDGE_GUARD, "", mode="stmt", nth=0),
    Mutant("targetguard", C, EDGE_GUARD, "", mode="stmt", nth=1),
    # (Occurrences 0 and 1 are the trapping spellings' preconditions.)
    Mutant("sourcelow", C, "edgeIndex >= 0 && edgeIndex < edgeCount", "edgeIndex >= -1 && edgeIndex < edgeCount", nth=2),
    Mutant("targethigh", C, "edgeIndex >= 0 && edgeIndex < edgeCount", "edgeIndex >= 0 && edgeIndex <= edgeCount", nth=3),

    # Each endpoint twin reads its own end.
    Mutant("sourceend", C, "return source(ofEdgeAt: edgeIndex)", "return target(ofEdgeAt: edgeIndex)", mode="stmt"),
    Mutant("targetend", C, "return target(ofEdgeAt: edgeIndex)", "return source(ofEdgeAt: edgeIndex)", mode="stmt", nth=1),
]

# Attached maps and generations (CompressedSparseRow+PropertyGraph.swift; the stamps in
# CompressedSparseRow.swift). The trapping subscripts' range preconditions get no mutants: the
# dense storage's own array read traps at the same positions, so removing one changes only the
# message.
P = "CompressedSparseRow+PropertyGraph.swift"
MUTANTS += [
    Mutant("mapstamp", C, "        _generation.stamp()", "", mode="stmt"),
    Mutant("mapemptybuild", C, "return CompressedSparseRow(_offsets: _emptyOffsets, _targets: [])", "return CompressedSparseRow()", mode="stmt"),
    Mutant("mapemptytranspose", C, "return CompressedSparseRow(_offsets: _offsets, _targets: _targets)", "return self", mode="stmt"),
    Mutant("mapsamesource", C, "_sourceGeneration = same.generation", "", mode="stmt"),
    Mutant("mapgraphsource", C, "_sourceGeneration = graph.generation", "", mode="stmt"),
    Mutant("mapiscurrent", C, "_sourceGeneration.isCurrent(for: graph)", "true"),
    # The size a new map is allocated with: occurrence 1 of `edgeCount` is the `add` call's, and
    # of `vertexCount` occurrence 2, since mapedgecount, planted first, adds one before it.
    Mutant("mapedgecount", P, "edgeCount", "vertexCount", nth=1),
    Mutant("mapvertexcount", P, "vertexCount", "edgeCount", nth=2),
    Mutant("mapcheckededgelow", P, "position >= 0 && position < edgeCount", "position < edgeCount", nth=2),
    Mutant("mapcheckededgehigh", P, "position >= 0 && position < edgeCount", "position >= 0 && position <= edgeCount", nth=2),
    Mutant("mapcheckedvertex", P, "guard contains(position) else { throw VertexNotFound() }", "", mode="stmt"),
]
