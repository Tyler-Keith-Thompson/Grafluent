# Planted bugs for Cliques; run with `just mutate Cliques`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   laterrows, forward  ranks are unique, so >= and > pick the same vertices.
#   colorbound          drops a pruning test: slower, the same answers.
#   pivotscore          the first pivot loop's ties by order met rather than by index: no graph
#                       among 3000 differential cases tells them apart (the X ∩ P members it
#                       passes over were branched on in the same frame). pivotscorex, the tie
#                       rule against X₀, is caught by CQ-1006.

TESTS = ["CliquesTests"]

MUTANTS = [
    # Simple rows
    Mutant("keeploops", "SimpleRows.swift", "w == v || stamp[w] == v", "stamp[w] == v"),
    Mutant("keeprepeats", "SimpleRows.swift", "w == v || stamp[w] == v", "w == v"),

    # Batagelj–Zaversnik
    Mutant("coredecrement", "SimpleRows.swift", "            degree[u] -= 1", "", mode="stmt"),
    Mutant("corecondition", "SimpleRows.swift", "degree[u] > degree[v]", "degree[u] >= degree[v]"),
    Mutant("corebin", "SimpleRows.swift", "            bin[du] += 1", "", mode="stmt"),
    Mutant("coreswap", "SimpleRows.swift", "u != w", "false"),

    # Maximal cliques
    Mutant("laterrows", "MaximalCliques.swift", "rank[rows.neighbors[k]] > rank[v]", "rank[rows.neighbors[k]] >= rank[v]"),
    Mutant("linkback", "MaximalCliques.swift", "                link(w, u)", "", mode="stmt"),
    Mutant("corefilter", "MaximumClique.swift", "core[later[k]] >= best", "core[later[k]] > best"),
    Mutant("singleton", "MaximalCliques.swift", "xVertices.isEmpty", "false"),
    Mutant("pivotscore", "MaximalCliques.swift", "score > bestScore || (score == bestScore && vertex < bestVertex)", "score > bestScore", nth=0),
    Mutant("pivotscorex", "MaximalCliques.swift", "score > bestScore || (score == bestScore && vertex < bestVertex)", "score >= bestScore", nth=1),
    Mutant("pivotbranches", "MaximalCliques.swift", "frames[base + k] & ~rowsP[best * pWords + k]", "frames[base + k]"),
    Mutant("movetox", "MaximalCliques.swift", "                frames[base + pWords + top >> 6] |= 1 << UInt64(top & 63)", "", mode="stmt"),
    Mutant("removefromp", "MaximalCliques.swift", "                frames[base + top >> 6] &= ~(1 << UInt64(top & 63))", "", mode="stmt"),
    Mutant("xhalf", "MaximalCliques.swift", "frames[base + 2 * pWords + k] & rowsX[w * xWords + k]", "frames[base + 2 * pWords + k]"),
    Mutant("cliquesort", "MaximalCliques.swift", "                    found.sort()", "", mode="stmt"),

    # Maximum clique
    Mutant("colorbound", "MaximumClique.swift", "chosen.count + colorBound(at: child) < need", "false"),
    Mutant("colorclass", "MaximumClique.swift", "                    for j in 0 ..< words { candidates[j] &= ~adjacency[i * words + j] }", "", mode="stmt"),
    Mutant("ceiling", "MaximumClique.swift", "core.max()! + 1", "core.max()!"),
    Mutant("corepruning", "MaximumClique.swift", "core[v] + 1 > best", "core[v] > best"),
    Mutant("lexleast", "MaximumClique.swift", "a.contains(least)", "!a.contains(least)"),

    # Triangles and clustering
    Mutant("forward", "Clustering.swift", "rank[rows.neighbors[k]] > rank[v]", "rank[rows.neighbors[k]] >= rank[v]"),
    Mutant("clusteringzero", "Clustering.swift", "degree < 2", "degree < 1"),
    Mutant("transitivity", "Clustering.swift", "Double(corners) / Double(triples)", "Double(corners / 3) / Double(triples)", nth=0),
    Mutant("transitivityoneshot", "Clustering.swift", "Double(corners) / Double(triples)", "Double(corners / 3) / Double(triples)", nth=1),
    Mutant("averagezeros", "Clustering.swift", "sum / Double(triangles.count)", "sum / Double(max(triangles.filter { $0 > 0 }.count, 1))", nth=0),
    Mutant("averageoneshot", "Clustering.swift", "sum / Double(triangles.count)", "sum / Double(max(triangles.filter { $0 > 0 }.count, 1))", nth=1),
    Mutant("localseen", "Clustering.swift", "around.contains(x) && seen.insert(x).inserted", "around.contains(x)", nth=0),

    # Preconditions
    Mutant("kcore", "CoreNumbers.swift", "precondition(k >= 0, \"k must be nonnegative\")", "precondition(true, \"k must be nonnegative\")", mode="stmt", nth=0),
]
