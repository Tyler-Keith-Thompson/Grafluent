# Planted bugs for Walks; run with `just mutate Walks`. See scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   closingstep  Wraps the step after the last vertex for open walks too: an open walk never asks
#                for it (it has one fewer edge than vertices), so nothing changes.

TESTS = ["WalksTests"]

MUTANTS = [
    # Rules
    Mutant("closedshape", "WalkSupport.swift",
           "vertexCount == edgeCount && vertexCount >= 1",
           "vertexCount == edgeCount"),
    Mutant("openshape", "WalkSupport.swift",
           "vertexCount == edgeCount + 1",
           "vertexCount >= edgeCount"),
    Mutant("distinctedges", "WalkSupport.swift",
           "        if distinctEdges && Set(edges).count != edges.count { return false }",
           "", mode="stmt"),
    Mutant("distinctvertices", "WalkSupport.swift",
           "        if distinctVertices && Set(vertices).count != vertices.count { return false }",
           "", mode="stmt"),
    Mutant("pathrule", "WalkSupport.swift",
           "Self(closed: false, distinctEdges: true, distinctVertices: true)",
           "Self(closed: false, distinctEdges: false, distinctVertices: true)"),
    Mutant("closingstep", "WalkSupport.swift",
           "closed && i + 1 == count ? 0 : i + 1",
           "i + 1 == count ? 0 : i + 1"),

    # Validation against a graph
    Mutant("directedcontains", "WalkSupport.swift",
           "        guard vertices.allSatisfy({ contains($0) }) else { return false }",
           "", mode="stmt", nth=0),
    Mutant("directedtarget", "WalkSupport.swift",
           "source(ofEdgeAt: e) != vertices[i] || target(ofEdgeAt: e) != vertices[rules.next(i, of: vertices.count)]",
           "source(ofEdgeAt: e) != vertices[i]"),
    Mutant("undirectedjoin", "WalkSupport.swift",
           "self.edges[e] != UndirectedEdge(vertices[i], vertices[rules.next(i, of: vertices.count)])",
           "!self.edges[e].isSelfLoop && self.edges[e].u != vertices[i] && self.edges[e].v != vertices[i]"),

    # Picking edges
    Mutant("directedunused", "WalkSupport.swift",
           "target(ofEdgeAt: $0) == to && (!rules.distinctEdges || !used.contains($0))",
           "target(ofEdgeAt: $0) == to"),
    Mutant("undirectedunused", "WalkSupport.swift",
           "oppositeVertex(to: from, acrossEdgeAt: $0) == to && (!rules.distinctEdges || !used.contains($0))",
           "oppositeVertex(to: from, acrossEdgeAt: $0) == to"),
    Mutant("pickclosing", "WalkSupport.swift",
           "rules.closed ? vertices.count : vertices.count - 1",
           "vertices.count - 1", nth=0),

    # Equality and hashing up to rotation
    Mutant("rotationoffset", "WalkSupport.swift",
           "k + i < n ? k + i : k + i - n",
           "i"),
    Mutant("rotationedges", "WalkSupport.swift",
           "if lv[j] != rv[i] || le[j] != re[i] { return false }",
           "if lv[j] != rv[i] { return false }", mode="stmt"),
    Mutant("rotationcount", "WalkSupport.swift",
           "    guard n == rv.count else { return false }",
           "", mode="stmt"),
    Mutant("hashorder", "WalkSupport.swift",
           "        sum &+= UInt(bitPattern: step.finalize())",
           "        sum = sum &* 31 &+ UInt(bitPattern: step.finalize())", mode="stmt"),
    Mutant("hashedge", "WalkSupport.swift",
           "        step.combine(edges[i])",
           "", mode="stmt"),

    # Members
    Mutant("cyclereversed", "Cycle.swift",
           "[_vertices[0]] + _vertices[1...].reversed()",
           "Array(_vertices.reversed())"),
    Mutant("walkappend", "Conversions.swift",
           "        _vertices.append(contentsOf: other._vertices.dropFirst())",
           "        _vertices.append(contentsOf: other._vertices)", mode="stmt"),
    Mutant("circuitopen", "Conversions.swift",
           "circuit._vertices + [circuit._vertices[0]]",
           "circuit._vertices", nth=0),
    Mutant("cycleclosedcheck", "Conversions.swift",
           "        guard !walk.isTrivial, walk.isClosed else { return nil }",
           "        guard !walk.isTrivial else { return nil }", mode="stmt", nth=1),
    Mutant("pathweight", "Path.swift",
           "        for e in _edges { total += try weight(e) }",
           "        for e in _edges.dropFirst() { total += try weight(e) }", mode="stmt"),
    Mutant("decodecheck", "Trail.swift",
           "Self._rules.holds(vertices, edges)",
           "true", nth=5),
]
