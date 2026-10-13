# Planted bugs for CompressedSparseRowModule's `checked:` spellings (README Principle 6): the range
# guard of each row lookup and of the checked edge endpoints, and each twin calling its own
# trapping spelling. Run with `just mutate CompressedSparseRowModule`. See scripts/mutate.py.
#
# The rest of the representation predates the mutation suite and has no mutants here yet.
#
# Known equivalent mutants (they survive by design): none.

TESTS = ["CompressedSparseRowTests"]

C = "CompressedSparseRow.swift"

ROW_GUARD = "guard contains(vertex) else { throw VertexNotFound() }"
EDGE_GUARD = "guard edgeIndex >= 0 && edgeIndex < edgeCount else { throw EdgeNotFound() }"

MUTANTS = [
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
