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
