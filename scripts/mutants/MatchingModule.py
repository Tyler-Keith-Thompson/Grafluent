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
#                           duals it sets are never read again; NetworkX notices only through its
#                           optimality self-check (MA-1002 is the input where that check fails).
#
# Order matters where patterns overlap: wdelta2 wraps the first `slack(bestEdge[v])` (δ₂'s), and
# its replacement then holds a `half(slack(bestEdge[v]))` ahead of δ₃'s, so wdelta3 takes nth=1.

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

    # Edmonds
    Mutant("edmondsodd", "CardinalityMatching.swift", "_find(&base, v) == _find(&base, w) || label[w] == 2", "_find(&base, v) == _find(&base, w)"),
    Mutant("edmondsbase", "CardinalityMatching.swift", "if _find(&base, x) == x { base[x] = a }", "", mode="stmt"),
    Mutant("edmondsrequeue", "CardinalityMatching.swift", "label[y] = 1", "", mode="stmt"),
    Mutant("edmondsreset", "CardinalityMatching.swift", "base[v] = v", "", mode="stmt"),
    Mutant("edmondsdead", "CardinalityMatching.swift", "if !augmented { for v in touched { dead[v] = true } }", "", mode="stmt"),
    Mutant("edmondsaugment", "CardinalityMatching.swift", "                            mateEdge[p] = linkEdge[t]", "", mode="stmt"),

    # Checks
    Mutant("checkrepeat", "CardinalityMatching.swift", "guard used.insert(position).inserted else { return nil }", "", mode="stmt"),
    Mutant("checkloop", "CardinalityMatching.swift", "guard edge.u != edge.v else { return nil }", "", mode="stmt"),
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

    # Weighted blossom (NetworkX's max_weight_matching)
    Mutant("wdeltatype1", "WeightedMatching.swift", "for v in 1 ..< n where dual[v] < delta { delta = dual[v] }", "", mode="stmt"),
    Mutant("wdelta2", "WeightedMatching.swift", "slack(bestEdge[v])", "half(slack(bestEdge[v]))", nth=0),
    Mutant("wdelta3", "WeightedMatching.swift", "half(slack(bestEdge[v]))", "slack(bestEdge[v])", nth=1),
    Mutant("wdelta4", "WeightedMatching.swift", "deltaType == -1 || dual[b] < delta", "deltaType == -1"),
    Mutant("wdualS", "WeightedMatching.swift", "                        dual[v] -= delta", "", mode="stmt"),
    Mutant("wdualT", "WeightedMatching.swift", "                        dual[v] += delta", "", mode="stmt"),
    Mutant("wblossomdual", "WeightedMatching.swift", "                            dual[b] += delta", "", mode="stmt"),
    Mutant("wallow", "WeightedMatching.swift", "if kslack <= .zero { allowed[e] = stage }", "if kslack < .zero { allowed[e] = stage }", mode="stmt"),
    Mutant("wbestedge", "WeightedMatching.swift", "if bestEdge[w] < 0 || kslack < slack(bestEdge[w]) { bestEdge[w] = a }", "if bestEdge[w] < 0 { bestEdge[w] = a }", mode="stmt"),
    Mutant("wclamp", "WeightedMatching.swift", "delta = least > .zero ? least : .zero", "delta = least", mode="stmt"),
    Mutant("wexpandzero", "WeightedMatching.swift", "dual[b] == .zero", "false"),

    # Stable matching
    Mutant("stableacceptable", "StableMatching.swift", "if mine < 0 { continue }", "", mode="stmt"),
    Mutant("stableprefer", "StableMatching.swift", "mine < theirs", "mine > theirs"),
    Mutant("stabledisplaced", "StableMatching.swift", "                free.append(current)", "", mode="stmt"),
]
