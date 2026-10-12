# Planted bugs for ShortestPaths; run with `just mutate ShortestPaths`. See scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   nohook     Turns off the compressed-sparse-row rows fast path; the general index-space path
#              gives the same results, only slower (the benchmarks cover it).
#   rounds     Lets Bellman–Ford run a few rounds past n. Without a negative cycle it stops
#              earlier anyway; with one the result is still nil, and only which cycle the witness
#              walk finds can change, which is unspecified.
#   walkbreak  Drops the early exit when a negative-cycle walk meets an earlier walk. An earlier
#              walk that found a cycle has returned, so the vertex leads to a root and the walk
#              ends there anyway: the result is the same, the cost quadratic in the worst case.
#
# Caught only by the time limit: queuedonce (queuing a vertex more than once per round multiplies
# the work without changing any result).

TESTS = ["ShortestPathsTests"]

MUTANTS = [
    # Index space
    Mutant("rowpos", "IndexSpace.swift",
           "unsafeBitCast(position, to: Index.self)",
           "unsafeBitCast(Swift.max(position - 1, 0), to: Index.self)"),
    Mutant("nohook", "IndexSpace.swift",
           "Edges.Index.self == Int.self",
           "Edges.Index.self == String.self", nth=0),

    # Undirected
    Mutant("orient", "Undirected.swift",
           "edges[position].u != vertex(atIndex: parent[v])",
           "false"),
    Mutant("nativeoff", "Undirected.swift",
           "vertexIndexBound != nil",
           "vertexIndexBound == nil", nth=0),

    # Bellman–Ford
    Mutant("queuedonce", "BellmanFord.swift",
           "queuedIn[v] != round",
           "true"),
    Mutant("rounds", "BellmanFord.swift",
           "round < n",
           "round < n + 5"),
    Mutant("walkbreak", "BellmanFord.swift",
           "            if walk[v] >= 0 { break }",
           "", mode="stmt"),
    Mutant("rotate", "BellmanFord.swift",
           "cycle.indices.min { cycle[$0] < cycle[$1] }!",
           "cycle.startIndex"),

    # Dijkstra and A*
    Mutant("astarreopen", "Dijkstra.swift",
           "parent[v] == -2 || candidate < distance[v]",
           "parent[v] == -2", nth=0),
    Mutant("cutoffincl", "Dijkstra.swift",
           "cutoff < candidate",
           "!(candidate < cutoff)"),
    Mutant("parentedge", "Dijkstra.swift",
           "                            parentEdge[v] = e",
           "", mode="stmt", nth=0),
    Mutant("relaxfirst", "Dijkstra.swift",
           "parent[v] == -2 || candidate < distance[v]",
           "parent[v] == -2", nth=1),
    Mutant("reached", "Dijkstra.swift",
           "        guard result.reachedTarget else { return nil }",
           "", mode="stmt"),

    Mutant("astartarget", "Dijkstra.swift",
           "            if target >= 0 { estimated[target] = true }",
           "", mode="stmt"),
    Mutant("nancutoff", "Dijkstra.swift",
           "cutoff.map { $0 == $0 } ?? true",
           "true"),
    Mutant("pathedges", "Dijkstra.swift",
           "            pathEdges.append(result.parentEdge[i])",
           "", mode="stmt"),

    # Undirected negative edges
    Mutant("negscan", "Undirected.swift",
           "if w < .zero { return (e, u) }",
           "if w < .zero && false { return (e, u) }", mode="stmt"),
    Mutant("negorder", "Undirected.swift",
           "first ? (u, v) : (v, u)",
           "(u, v)"),
    Mutant("negselfloop", "Undirected.swift",
           "        if u == v { return Cycle(_uncheckedVertices: [u], edges: [DirectedView<Self>.Edges.Index(position: edge, reversed: false)]) }",
           "", mode="stmt"),
    Mutant("wholegraph", "Undirected.swift",
           "for e in incidentEdges(of: u) where weight(e) < .zero { return (e, u) }",
           "for e in incidentEdges(of: u) where weight(e) < .zero && false { return (e, u) }", mode="stmt"),
    Mutant("nancutoffundirected", "Undirected.swift",
           "cutoff.map { $0 == $0 } ?? true",
           "true"),

    # Walks: the edges of witnesses and paths
    Mutant("witnessedges", "BellmanFord.swift",
           "result.parentEdge[cycle[($0 + 1) % n]]",
           "result.parentEdge[cycle[$0]]"),
    Mutant("witnessarc", "Undirected.swift",
           "self.edges[edge].u != x",
           "self.edges[edge].u == x"),
    Mutant("pathedgeorder", "ShortestPathTree.swift",
           "        edges.reverse()",
           "", mode="stmt", nth=0),

    # The tree
    Mutant("dedup", "ShortestPathTree.swift",
           "seen.insert(i).inserted",
           "seen.insert(i).inserted || true"),
    Mutant("emptysrc", "ShortestPathTree.swift",
           '        precondition(allowsEmpty || !indices.isEmpty, "A shortest-path search needs at least one source")',
           "", mode="stmt"),
    Mutant("treepathedges", "ShortestPathTree.swift",
           "            edges.append(_parentEdge[i])",
           "", mode="stmt"),
    Mutant("singlesource", "ShortestPathTree.swift",
           "            return ([_index(of: only.first!, ids)], [only.first!])",
           "            return ([0], [only.first!])", mode="stmt"),
    Mutant("treepath", "ShortestPathTree.swift",
           "        guard _parent[i] != Self._unreached else { return nil }",
           "", mode="stmt"),

    # reuse pass (C)
    Mutant("pooledpos", "IndexSpace.swift",
           "unsafeBitCast(edges[k], to: Index.self)",
           "unsafeBitCast(targets[k], to: Index.self)", nth=0),
    Mutant("pooledstart", "IndexSpace.swift",
           "(edges.baseAddress ?? placeholder) + edgeRows[3 &* row]",
           "(edges.baseAddress ?? placeholder) + 0"),

    # reuse pass (D): Arborescence(_: ShortestPathTree)
    Mutant("sa_sources", "ShortestPathTree.swift",
           "tree.sources.count == 1",
           "tree.sources.count >= 1", nth=1),
    Mutant("sa_reached", "ShortestPathTree.swift",
           "parent[i] != unreached",
           "true", nth=0),
    Mutant("sa_parent", "ShortestPathTree.swift",
           "parents[number[i]] = number[parent[i]]",
           "parents[number[i]] = parent[i]", nth=0),

    # The checked: spellings: the one lookup that throws, and each spelling's own reading.
    Mutant("checkedindex", "IndexSpace.swift",
           "ids.existingIdentifier(of: vertex)",
           "Optional(ids.existingIdentifier(of: vertex) ?? 0)", nth=1),
    Mutant("checkedhaspath", "ShortestPathTree.swift",
           "Self._unreached",
           "Self._source", nth=3),
    Mutant("checkedparent", "ShortestPathTree.swift",
           "_ids.vertex($0)",
           "_ids.vertex(0)", nth=1),
    Mutant("checkedmatrixdistance", "DistanceMatrix.swift",
           "distance(fromIndex: i, toIndex: j)",
           "distance(fromIndex: j, toIndex: i)", nth=1),
    Mutant("checkedmatrixhaspath", "DistanceMatrix.swift",
           "_hasPath(i, j)",
           "_hasPath(j, i)"),
    Mutant("checkedmatrixpath", "DistanceMatrix.swift",
           "_path(i, j)",
           "_path(j, i)"),
    Mutant("checkedarborescence", "ShortestPathTree.swift",
           "        guard tree.sources.count == 1 else { throw NotATree() }",
           "        guard tree.sources.count >= 1 else { throw NotATree() }", mode="stmt"),

    # Forest(_: ShortestPathTree) and the Forest initializer it builds through.
    Mutant("forestreached", "ShortestPathTree.swift",
           "parent[i] != unreached",
           "parent[i] >= 0", nth=1),
    Mutant("forestparent", "ShortestPathTree.swift",
           "parents[number[i]] = number[parent[i]]",
           "parents[number[i]] = parent[i]", nth=1),
    Mutant("forestroots", "Forest.swift",
           "p >= 0",
           "p > 0", module="Trees"),
    Mutant("forestends", "Forest.swift",
           "            ends.append(p)\n            ends.append(v)",
           "            ends.append(v)\n            ends.append(p)", mode="stmt", module="Trees"),
]
