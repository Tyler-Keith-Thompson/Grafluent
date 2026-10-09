# Planted bugs for Cycles; run with `just mutate Cycles`. See scripts/mutate.py.
#
# Known equivalent mutants are left out rather than listed: widening a piece (bridges as pieces,
# not skipping the parent edge in the block search) or what girth searches (single-vertex strong
# components, leaving a component) only makes a search slower, and loosening a stopping rule
# (girth's depth bound, the O(1) shortcut in isAcyclic) only makes it longer.

TESTS = ["CyclesTests"]

MUTANTS = [
    # Simple cycles: closures at s
    Mutant("sameedge", "SimpleCycleSearch.swift", "e <= pathEdges[1]", "e < pathEdges[1]"),
    Mutant("orientation", "SimpleCycleSearch.swift", "e <= pathEdges[1]", "e == pathEdges[1]"),
    Mutant("loopdup", "SimpleCycleSearch.swift", "seenLoop[e] == s", "false"),
    Mutant("foundclosure", "SimpleCycleSearch.swift",
           "                    if bounded { blen[d] = 1 } else { found[d] = true }",
           "                    if !emit { } else if bounded { blen[d] = 1 } else { found[d] = true }", mode="stmt"),
    Mutant("lowerskip", "SimpleCycleSearch.swift", "                if w < s { continue }", "", mode="stmt"),

    # Johnson's blocking
    Mutant("foundup", "SimpleCycleSearch.swift", "                        found[d - 1] = true", "", mode="stmt"),
    Mutant("blockpush", "SimpleCycleSearch.swift", "            blocked[w] = true", "", mode="stmt"),

    # Gupta–Suzumura's locks
    Mutant("relaxoff", "SimpleCycleSearch.swift", "bl < maxLength", "false"),
    Mutant("relaxbound", "SimpleCycleSearch.swift", "maxLength - b + 1", "maxLength - b"),
    Mutant("lockpush", "SimpleCycleSearch.swift", "path.count < lock[w]", "path.count <= lock[w]"),
    Mutant("blenmin", "SimpleCycleSearch.swift", "min(blen[d - 1], bl)", "blen[d - 1]"),
    Mutant("boundedswitch", "SimpleCycleSearch.swift", "maxLength < n", "false"),

    # Pieces
    Mutant("endround", "SimpleCycleSearch.swift", "sources[slot] != s && rows.targets[slot] != s", "rows.targets[slot] != s"),
    Mutant("lazystate", "SimpleCycleSearch.swift", "stamp[v] != round", "stamp[v] < 0"),
    Mutant("sccarcs", "SimpleCycleSearch.swift", "group[rows.targets[slot]] == c", "group[rows.targets[slot]] >= 0"),
    Mutant("blocksize", "SimpleCycleSearch.swift", "size >= 2", "size >= 3"),
    Mutant("startorder", "SimpleCycleSearch.swift", "bounded || selected.count > 1", "false"),
    Mutant("looppieces", "SimpleCycleSearch.swift", "                if !loopArcs.isEmpty { addPiece(loopArcs) }", "", mode="stmt"),
    Mutant("tarjanback", "SimpleCycleSearch.swift", "                        low[v] = min(low[v], disc[w])", "", mode="stmt", nth=0),
    Mutant("blockback", "SimpleCycleSearch.swift", "disc[w] < disc[v]", "false"),

    # Canonical form
    Mutant("rotation", "CycleRows.swift", "vertices[i] < vertices[r]", "vertices[i] > vertices[r]"),
    Mutant("reflection", "CycleRows.swift", "es[n - 1] < es[0]", "es[n - 1] > es[0]"),

    # isAcyclic, findCycle
    Mutant("emptyforest", "UndirectedCycles.swift", "edgeCount >= max(vertexCount, 1)", "edgeCount >= vertexCount"),
    Mutant("joinedonce", "UndirectedCycles.swift", "                if joined[e] { continue }", "", mode="stmt"),
    Mutant("findparent", "UndirectedCycles.swift", "                    if e == arrived { continue }", "", mode="stmt"),
    Mutant("findroots", "UndirectedCycles.swift", "_findCycle(roots: numbers)", "_findCycle(roots: Array(numbers.prefix(1)))"),

    # Cycle basis
    Mutant("treeedge", "UndirectedCycles.swift", "                    isTree[e] = true", "", mode="stmt"),
    Mutant("lcaorder", "UndirectedCycles.swift", "edgesB.reversed()", "edgesB"),
    Mutant("bfsdfs", "UndirectedCycles.swift", "queue[head]", "queue[queue.count - 1]"),

    # Girth
    Mutant("girthstop", "Girth.swift", "2 * dist[v] + 1 >= best", "2 * dist[v] + 3 >= best"),
    Mutant("girthcore", "Girth.swift", "degree[w] <= 1", "degree[w] <= 2"),
    Mutant("girthcorestart", "Girth.swift", "degree[$0] <= 1", "degree[$0] <= 2"),

    # Rows and positions
    Mutant("rowends", "CycleRows.swift", "$0 == 2", "$0 >= 1"),
    Mutant("positionwalk", "CycleRows.swift", "offset < numbers[k]", "offset < numbers[k] - 1"),
    Mutant("findedgerange", "UndirectedCycles.swift", "UInt(bitPattern: e) < UInt(bitPattern: edgeCount)", "true", nth=1),
    Mutant("girthparent", "Girth.swift", "e == parentEdge[v]", "false"),
    Mutant("girthdirected", "Girth.swift", "best = dist[v] + 1", "best = dist[v] + 2"),

    # Preconditions
    Mutant("negativebound", "SimpleCycles.swift", "maxLength >= 0", "true", nth=1),
    Mutant("negativeboundundirected", "SimpleCycles.swift", "maxLength >= 0", "true", nth=3),
]
