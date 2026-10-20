# Planted bugs for Cycles; run with `just mutate Cycles`. See scripts/mutate.py.
#
# Known equivalent mutants are left out rather than listed: widening a piece (bridges as pieces,
# not skipping the parent edge in the block search) or what girth searches (single-vertex strong
# components, leaving a component) only makes a search slower, and loosening a stopping rule
# (girth's depth bound, the O(1) shortcut in isAcyclic) only makes it longer. Karp's block size
# and keeping every level (minimumMeanCycle) only trade memory for time, and chordlessCycles'
# bound on entering a vertex only prunes: the bound on closing a cycle decides what is emitted.
# In minimumCycleBasis, the searches' stop once they cannot beat the best cycle so far only
# prunes, and accepting a later cycle of equal weight picks another of the tied minimum bases.

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
    Mutant("rotation", "Cycle.swift", "vertices[i] < vertices[r]", "vertices[i] > vertices[r]", module="Walks"),
    Mutant("reflection", "Cycle.swift", "es[n - 1] < es[0]", "es[n - 1] > es[0]", module="Walks"),

    # isAcyclic, findCycle
    Mutant("emptyforest", "UndirectedCycles.swift", "edgeCount >= max(vertexCount, 1)", "edgeCount >= vertexCount"),
    Mutant("joinedonce", "UndirectedCycles.swift", "                if joined[e] { continue }", "", mode="stmt"),
    Mutant("findparent", "UndirectedCycles.swift", "                    if e == arrived { continue }", "", mode="stmt"),
    Mutant("findroots", "UndirectedCycles.swift", "_findCycle(roots: numbers)", "_findCycle(roots: Array(numbers.prefix(1)))"),

    # Cycle basis
    Mutant("treeedge", "UndirectedCycles.swift", "                    isTree[e] = true", "", mode="stmt"),
    Mutant("lcaorder", "UndirectedCycles.swift", "edgesB.reversed()", "edgesB"),
    Mutant("bfsdfs", "UndirectedCycles.swift", "queue[head]", "queue[queue.count - 1]"),

    # Minimum cycle basis
    Mutant("mcbtree", "MinimumCycleBasis.swift", "                    isTree[e] = true", "", mode="stmt"),
    Mutant("mcbparity", "MinimumCycleBasis.swift", "inSupport[e]", "true", nth=1),
    Mutant("mcbbfsparity", "MinimumCycleBasis.swift", "inSupport[e]", "true", nth=2),
    Mutant("mcbrelax", "MinimumCycleBasis.swift", "nd < distance[t]", "false"),
    Mutant("mcbodd", "MinimumCycleBasis.swift", "guard overlap & 1 == 1 else { continue }", "guard overlap > 0 else { continue }", mode="stmt"),
    Mutant("mcbupdate", "MinimumCycleBasis.swift", "supports[j] = merged", "", mode="stmt"),
    Mutant("mcbsupport", "MinimumCycleBasis.swift", "merged.append(support[b])", "merged.append(cycle[b])", mode="stmt"),
    Mutant("mcbunmark", "MinimumCycleBasis.swift", "for e in support { inSupport[e] = false }", "", mode="stmt"),
    Mutant("mcbsort", "MinimumCycleBasis.swift", "if x.weight != y.weight { return x.weight < y.weight }", "", mode="stmt"),
    Mutant("mcbsortlength", "MinimumCycleBasis.swift", "if x.edges.count != y.edges.count { return x.edges.count < y.edges.count }", "", mode="stmt"),
    Mutant("mcbweightcheck", "MinimumCycleBasis.swift", "w.isFinite && w > 0", "w.isFinite && w >= 0"),
    Mutant("mcbwalk", "MinimumCycleBasis.swift", "vertices.reverse()", "", mode="stmt"),

    # Girth
    Mutant("girthstop", "Girth.swift", "2 * dist[v] + 1 >= best", "2 * dist[v] + 3 >= best"),
    Mutant("girthcore", "Girth.swift", "degree[w] <= 1", "degree[w] <= 2"),
    Mutant("girthcorestart", "Girth.swift", "degree[$0] <= 1", "degree[$0] <= 2"),

    # Rows and positions
    Mutant("rowends", "CycleRows.swift", "$0 == 2", "$0 >= 1"),
    Mutant("positionwalk", "UndirectedRows.swift", "offset < numbers[k]", "offset < numbers[k] - 1", module="GraphProtocols"),
    Mutant("findedgerange", "UndirectedCycles.swift", "UInt(bitPattern: e) < UInt(bitPattern: edgeCount)", "true", nth=1),
    Mutant("girthparent", "Girth.swift", "e == parentEdge[v]", "false"),
    Mutant("girthdirected", "Girth.swift", "best = dist[v] + 1", "best = dist[v] + 2"),

    # Preconditions
    Mutant("negativebound", "SimpleCycles.swift", "maxLength >= 0", "true", nth=1),
    Mutant("negativeboundundirected", "SimpleCycles.swift", "maxLength >= 0", "true", nth=3),

    # reuse pass (C)
    Mutant("girthsccsize", "Girth.swift", "size[components[v]] >= 2", "size[components[v]] >= 3"),

    # chordlessCycles
    Mutant("cc_joined", "ChordlessCycles.swift", "joined[w] == 1", "joined[w] >= 1"),
    Mutant("cc_oneloop", "ChordlessCycles.swift", "                guard loops[s] == 1 else { continue }", "", mode="stmt"),
    Mutant("cc_loopends", "ChordlessCycles.swift", "            if rows.undirected { loops[v] /= 2 }", "", mode="stmt"),
    Mutant("cc_rootloops", "ChordlessCycles.swift", "loops[w] == 0", "true", nth=0),
    Mutant("cc_pathloops", "ChordlessCycles.swift", "loops[w] == 0", "true", nth=1),
    Mutant("cc_orientation", "ChordlessCycles.swift", "pathEdges[0] > backEdge", "pathEdges[0] < backEdge"),
    Mutant("cc_digonorientation", "ChordlessCycles.swift", "e < rows.edges[other]", "e > rows.edges[other]"),
    Mutant("cc_digon", "ChordlessCycles.swift", "fromRoot[w] == 2", "fromRoot[w] >= 2"),
    Mutant("cc_rootchord", "ChordlessCycles.swift", "        if !rows.undirected && fromRoot[w] != 0 { return false }", "", mode="stmt"),
    Mutant("cc_inrow", "ChordlessCycles.swift",
           "            for k in inOffsets[w] ..< inOffsets[w + 1] { joined[sources[inSlots[k]]] += delta }",
           "", mode="stmt"),
    Mutant("cc_endroot", "ChordlessCycles.swift", "            fromRoot[w] = 0", "", mode="stmt"),
    Mutant("cc_endrootin", "ChordlessCycles.swift", "                toRoot[u] = 0", "", mode="stmt"),

    # minimumMeanCycle
    Mutant("mm_compare", "MinimumMeanCycle.swift", "a * W(exactly: d)! < c * W(exactly: b)!", "a * W(exactly: b)! < c * W(exactly: d)!"),
    Mutant("mm_greatest", "MinimumMeanCycle.swift",
           "!Self._less(old.numerator, old.denominator, fraction.numerator, fraction.denominator)",
           "Self._less(old.numerator, old.denominator, fraction.numerator, fraction.denominator)"),
    Mutant("mm_least", "MinimumMeanCycle.swift",
           "Self._less(f.numerator, f.denominator, best[end]!.numerator, best[end]!.denominator)",
           "!Self._less(f.numerator, f.denominator, best[end]!.numerator, best[end]!.denominator)"),
    Mutant("mm_checkpoint", "MinimumMeanCycle.swift", "checkpoints[start / b]", "checkpoints[0]"),
    Mutant("mm_fulllevel", "MinimumMeanCycle.swift", "checkpoints[k + 1]", "checkpoints[k]"),
    Mutant("mm_rotate", "MinimumMeanCycle.swift", "                slots = Array(slots[least...] + slots[..<least])", "", mode="stmt"),
    Mutant("mm_relax", "MinimumMeanCycle.swift", "dw <= candidate", "dw >= candidate"),
]
