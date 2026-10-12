# Planted bugs for AdjacencyMatrixModule's `checked:` spellings (README Principle 6): the range
# guard of each row lookup, the cell guard of the checked edge endpoints, the endpoints checked by
# `insert(checked:)`, and each twin calling its own trapping spelling. Run with
# `just mutate AdjacencyMatrixModule`. See scripts/mutate.py.
#
# The rest of the matrix predates the mutation suite and has no mutants here yet.
#
# Known equivalent mutants (they survive by design): none.

TESTS = ["AdjacencyMatrixTests"]

M = "AdjacencyMatrix.swift"

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
]
