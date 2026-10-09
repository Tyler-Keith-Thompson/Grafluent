# Planted bugs for Cliques; run with `just mutate Cliques`. See scripts/mutate.py.

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
    Mutant("pafter", "MaximalCliques.swift", "rank[u] > rank[v]", "rank[u] >= rank[v]"),
    Mutant("singleton", "MaximalCliques.swift", "xVertices.isEmpty ? [v] : nil", "nil"),
    Mutant("pivotscore", "MaximalCliques.swift", "score > bestScore || (score == bestScore && vertex < bestVertex)", "score > bestScore"),
    Mutant("pivotbranches", "MaximalCliques.swift", "frame[k] & ~rowsP[best * pWords + k]", "frame[k]"),
    Mutant("movetox", "MaximalCliques.swift", "                frames[base + pWords + top >> 6] |= 1 << UInt64(top & 63)", "", mode="stmt"),
    Mutant("removefromp", "MaximalCliques.swift", "                frames[base + top >> 6] &= ~(1 << UInt64(top & 63))", "", mode="stmt"),
    Mutant("xhalf", "MaximalCliques.swift", "frames[base + 2 * pWords + k] & rowsX[w * xWords + k]", "frames[base + 2 * pWords + k]"),
    Mutant("cliquesort", "MaximalCliques.swift", "                    result.sort()", "", mode="stmt"),

    # Maximum clique
    Mutant("colorbound", "MaximumClique.swift", "chosen.count + colorBound(set) >= size", "chosen.count + colorBound(set) > size"),
    Mutant("colorclass", "MaximumClique.swift", "                    for j in 0 ..< words { candidates[j] &= ~adjacency[i * words + j] }", "", mode="stmt"),
    Mutant("ceiling", "MaximumClique.swift", "core.max()! + 1", "core.max()!"),
    Mutant("corepruning", "MaximumClique.swift", "core[v] + 1 > best", "core[v] > best"),
    Mutant("lexleast", "MaximumClique.swift", "rows.neighbors[k] > v", "rows.neighbors[k] != v"),

    # Triangles and clustering
    Mutant("forward", "Clustering.swift", "rank[rows.neighbors[k]] > rank[v]", "rank[rows.neighbors[k]] >= rank[v]"),
    Mutant("clusteringzero", "Clustering.swift", "degree < 2 ? 0 : Double(2 * triangles)", "degree < 1 ? 0 : Double(2 * triangles)"),
    Mutant("transitivity", "Clustering.swift", "Double(corners) / Double(triples)", "Double(corners / 3) / Double(triples)"),
    Mutant("averagezeros", "Clustering.swift", "sum / Double(triangles.count)", "sum / Double(max(triangles.filter { $0 > 0 }.count, 1))"),
    Mutant("localseen", "Clustering.swift", "around.contains(x) && seen.insert(x).inserted", "around.contains(x)", nth=0),

    # Preconditions
    Mutant("kcore", "CoreNumbers.swift", "precondition(k >= 0, \"k must be nonnegative\")", "precondition(true, \"k must be nonnegative\")", mode="stmt", nth=0),
]
