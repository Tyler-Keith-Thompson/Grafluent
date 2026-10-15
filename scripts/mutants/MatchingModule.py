# Planted bugs for MatchingModule; run with `just mutate MatchingModule`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   hkfreelayer, hkdeeper   breadth-first layers put every reachable left vertex at most one layer
#                           below its predecessor, so the first free layer found is the only one
#                           met, and `>= next` is `== next`.
#   hklayerstop, hkremove,  extra work only: layering past the free layer, re-entering a vertex
#   hkparentcursor          whose search failed, or retrying a slot whose subtree failed finds no
#                           path the original would not.
#   edmondsdead             the pruning: a failed search's vertices are on no later augmenting
#                           path, so searches that include them find the same augmentations.
#   checkrepeat             a repeated position covers its ends twice, which the shared-end test
#                           rejects.
#   fullemptyrow            the early exit for a row with no edge: the engine reaches nil too.
#   wclamp                  the final δ₁ ends the search at once (deltaType 1 breaks out), so the
#                           duals it sets are never read again; only an optimality self-check would
#                           notice (MA-1002 is an input where such a check fails).
#   wmincost                `c = greatest` instead of 1 + greatest: the transform runs
#                           with maximumCardinality, where every candidate has the same number of
#                           edges, so a constant added to every weight moves no optimum (the
#                           weights stay non-negative, and the search never needs them positive).
#
# The cached slacks (bestSlack), which δ₂ and δ₃ read too: wrefresh and wrefreshvertices,
# the refresh after a dual update dropped or limited to vertices, are caught only by non-dyadic
# Double weights on enough random graphs (MatchingStressTests' subset program): with small
# integers the stale slack rarely reorders two candidates. wchosenslack, a new blossom's slack
# left unset, is caught by the catalog since δ₃ reads it.
#
# Order matters where patterns overlap: wdelta2 wraps the first `bestSlack[v]` (δ₂'s), and its
# replacement then holds a `half(bestSlack[v])` ahead of δ₃'s, so wdelta3 takes nth=1.

TESTS = ["MatchingModuleTests"]

MUTANTS = [
    # Matching
    Mutant("perfect", "Matching.swift", "2 * edges.count == _mate.count", "edges.count == _mate.count"),
    Mutant("slot", "Matching.swift", "            slot[structure.to[e]] = numbers.count", "", mode="stmt"),

    # Greedy
    Mutant("greedyloop", "CardinalityMatching.swift", "u != v", "true", nth=0),

    # Hopcroft–Karp
    Mutant("hkfreelayer", "CardinalityMatching.swift", "if free == infinity { free = layer[v] + 1 }", "free = layer[v] + 1", mode="stmt"),
    Mutant("hklayerstop", "CardinalityMatching.swift", "guard layer[v] < free else { continue }", "", mode="stmt"),
    Mutant("hkremove", "CardinalityMatching.swift", "layer[v] = infinity", "", nth=1, mode="stmt"),
    Mutant("hkdeeper", "CardinalityMatching.swift", "layer[p] == next", "layer[p] >= next && layer[p] != infinity"),
    Mutant("hkparentcursor", "CardinalityMatching.swift", "if let parent = stack.last { stack[stack.count - 1].slot = parent.slot + 1 }", "", mode="stmt"),
    # Hopcroft–Karp as an event sequence
    Mutant("hkeobserve", "CardinalityMatching.swift", "observer.augmenting(stack, mateSlot: mateSlot)", "", mode="stmt"),
    Mutant("hkelayered", "CardinalityMatching.swift", "observer.layered(free: free)", "", mode="stmt"),
    Mutant("hkelength", "HopcroftKarpEvents.swift", "2 * free - 1", "free"),
    Mutant("hkematched", "HopcroftKarpEvents.swift", "if i > 0 { path.append(positions[slotEdges[mateSlot[v]]]) }", "", mode="stmt"),

    # Edmonds
    Mutant("edmondsodd", "CardinalityMatching.swift", "_find(&base, v) == _find(&base, w) || label[w] == 2", "_find(&base, v) == _find(&base, w)"),
    Mutant("edmondsbase", "CardinalityMatching.swift", "if _find(&base, x) == x { base[x] = a }", "", mode="stmt"),
    Mutant("edmondsrequeue", "CardinalityMatching.swift", "label[y] = 1", "", mode="stmt"),
    Mutant("edmondsreset", "CardinalityMatching.swift", "base[v] = v", "", mode="stmt"),
    Mutant("edmondsdead", "CardinalityMatching.swift", "if !augmented { for v in touched { dead[v] = true } }", "", mode="stmt"),
    Mutant("edmondsaugment", "CardinalityMatching.swift", "                            mateEdge[p] = linkEdge[t]", "", mode="stmt"),

    # Checks
    Mutant("checkrepeat", "CardinalityMatching.swift", "guard used.insert(position).inserted else { return nil }", "", mode="stmt"),
    Mutant("checkloop", "CardinalityMatching.swift", "            guard u != v, !covered[u], !covered[v] else { return nil }", "            guard !covered[u], !covered[v] else { return nil }", mode="stmt"),
    Mutant("maximalloop", "CardinalityMatching.swift", "if u != v, !covered[u], !covered[v] { return false }", "if !covered[u], !covered[v] { return false }", mode="stmt"),

    # Assignment
    Mutant("lsapreverse", "Assignment.swift", "for k in 0 ..< nc { remaining[k] = nc - k - 1 }", "for k in 0 ..< nc { remaining[k] = k }", mode="stmt"),
    Mutant("lsapunassigned", "Assignment.swift", "index == -1 || less || (equal && row4col[j] == -1)", "index == -1 || less"),
    Mutant("lsappotential", "Assignment.swift", "            u[r] += minimum - shortest[col4row[r]]", "", mode="stmt"),
    Mutant("lsapcolumns", "Assignment.swift", "            v[c] -= minimum - shortest[c]", "", mode="stmt"),
    Mutant("lsaptranspose", "Assignment.swift", "columnCount < rowCount", "false"),
    Mutant("lsapdensemaximize", "Assignment.swift", "values[i * nc + j] = maximize ? -x : x", "values[i * nc + j] = x", mode="stmt"),
    Mutant("lsapdensetranspose", "Assignment.swift", "transposed ? cost(j, i) : cost(i, j)", "cost(i, j)"),
    Mutant("fullemptyrow", "Assignment.swift", "for r in rowSide.indices where offsets[r] == offsets[r + 1] { return nil }", "", mode="stmt"),
    Mutant("lsapinfeasible", "Assignment.swift", "guard lowestReached else { return nil }", "", mode="stmt"),
    Mutant("fulllightest", "Assignment.swift", "w < costs[k] || (w == costs[k] && e < edges[k])", "w > costs[k]"),
    Mutant("fulltranspose", "Assignment.swift", "left.count <= right.count", "true"),

    # Weighted blossom
    Mutant("wdeltatype1", "WeightedMatching.swift", "for v in 1 ..< n where dual[v] < delta { delta = dual[v] }", "", mode="stmt"),
    Mutant("wdelta2", "WeightedMatching.swift", "bestSlack[v]", "half(bestSlack[v])", nth=0),
    Mutant("wdelta3", "WeightedMatching.swift", "half(bestSlack[v])", "bestSlack[v]", nth=1),
    Mutant("wdelta3blossom", "WeightedMatching.swift", "half(bestSlack[b])", "bestSlack[b]"),
    Mutant("wdelta4", "WeightedMatching.swift", "deltaType == -1 || dual[b] < delta", "deltaType == -1"),
    Mutant("wdualS", "WeightedMatching.swift", "                        dual[v] -= delta", "", mode="stmt"),
    Mutant("wdualT", "WeightedMatching.swift", "                        dual[v] += delta", "", mode="stmt"),
    Mutant("wblossomdual", "WeightedMatching.swift", "                            dual[b] += delta", "", mode="stmt"),
    Mutant("wallow", "WeightedMatching.swift", "if kslack <= .zero { allowed[e] = current }", "if kslack < .zero { allowed[e] = current }", mode="stmt"),
    Mutant("wbestedge", "WeightedMatching.swift", "bestEdge[w] < 0 || kslack < bestSlack[w]", "bestEdge[w] < 0"),
    Mutant("wbestedgeS", "WeightedMatching.swift", "bestEdge[bv] < 0 || kslack < bestSlack[bv]", "bestEdge[bv] < 0"),
    Mutant("wbestslack", "WeightedMatching.swift", "                                bestSlack[w] = kslack", "", mode="stmt"),
    Mutant("wbestslackS", "WeightedMatching.swift", "                                bestSlack[bv] = kslack", "", mode="stmt"),
    Mutant("wrefresh", "WeightedMatching.swift", "                for x in 0 ..< 2 * n where bestEdge[x] >= 0 { bestSlack[x] = slack(bestEdge[x]) }", "", mode="stmt"),
    Mutant("wrefreshvertices", "WeightedMatching.swift", "                for x in 0 ..< 2 * n where bestEdge[x] >= 0 { bestSlack[x] = slack(bestEdge[x]) }", "                for x in 0 ..< n where bestEdge[x] >= 0 { bestSlack[x] = slack(bestEdge[x]) }", mode="stmt", nth=0),
    Mutant("wchosen", "WeightedMatching.swift", "chosen < 0 || s < chosenSlack", "chosen < 0"),
    Mutant("wchosenslack", "WeightedMatching.swift", "        if chosen >= 0 { bestSlack[b] = chosenSlack }", "", mode="stmt"),
    Mutant("warcslack", "WeightedMatching.swift", "dual[v] + dual[w] - (weight + weight)", "dual[v] + dual[w] - weight"),
    Mutant("wheaviestcopy", "WeightedMatching.swift", "weights[e] > weights[b] || (weights[e] == weights[b] && e < b)", "weights[e] < weights[b]"),
    Mutant("wmincost", "WeightedMatching.swift", "1 + greatest", "greatest"),
    Mutant("wmininvert", "WeightedMatching.swift", "        for e in 0 ..< structure.edgeCount where structure.from[e] != structure.to[e] { inverted[e] = c - weights[e] }", "", mode="stmt"),
    Mutant("wclamp", "WeightedMatching.swift", "delta = least > .zero ? least : .zero", "delta = least", mode="stmt"),
    Mutant("wexpandzero", "WeightedMatching.swift", "dual[b] == .zero", "false"),

    # Stable matching
    Mutant("stableacceptable", "StableMatching.swift", "if mine < 0 { continue }", "", mode="stmt"),
    Mutant("stableprefer", "StableMatching.swift", "mine < theirs", "mine > theirs"),
    Mutant("stabledisplaced", "StableMatching.swift", "                free.append(current)", "", mode="stmt"),

    # The checked: spellings
    Mutant("checkedmate", "Matching.swift", "        guard _graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("checkededge", "Matching.swift", "        guard _graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1),
    Mutant("checkedproposer", "StableMatching.swift", "proposer >= 0 && proposer < _proposerMates.count", "proposer < _proposerMates.count", nth=1),
    Mutant("checkedreviewer", "StableMatching.swift", "reviewer >= 0 && reviewer < _reviewerMates.count", "reviewer >= 0", nth=1),
]
