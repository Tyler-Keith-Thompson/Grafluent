# Planted bugs for Cliques; run with `just mutate Cliques`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   laterrows, forward  ranks are unique, so >= and > pick the same vertices.
#   bbmc_bound          `<` for `<=` in the colour bound prunes less: the same optimum, slower.
#   pivotscore          the first pivot loop's ties by order met rather than by index: no graph
#                       among 3000 differential cases tells them apart (the X ∩ P members it
#                       passes over were branched on in the same frame). pivotscorex, the tie
#                       rule against X₀, is caught by CQ-1006.

TESTS = ["CliquesTests"]

MUTANTS = [
    # Simple rows
    Mutant("keeploops", "CompressedRows.swift", "w == v", "false", nth=1, module="GraphProtocols"),
    Mutant("keeprepeats", "CompressedRows.swift", "                if stamp[w] == v { continue }", "", mode="stmt", module="GraphProtocols"),

    # Batagelj–Zaversnik
    Mutant("coredecrement", "SimpleRows.swift", "            degree[u] -= 1", "", mode="stmt"),
    Mutant("corecondition", "SimpleRows.swift", "degree[u] > degree[v]", "degree[u] >= degree[v]"),
    Mutant("corebin", "SimpleRows.swift", "            bin[du] += 1", "", mode="stmt"),
    Mutant("coreswap", "SimpleRows.swift", "u != w", "false"),

    # Maximal cliques
    Mutant("laterrows", "MaximalCliques.swift", "rank[rows.targets[k]] > rank[v]", "rank[rows.targets[k]] >= rank[v]"),
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
    Mutant("ceiling", "MaximumClique.swift", "core.max()! + 1", "core.max()!"),
    Mutant("corepruning", "MaximumClique.swift", "core[v] + 1 > clique.count", "core[v] > clique.count"),
    Mutant("subrows", "MaximumClique.swift", "                engine.rows[j * words + i >> 6] |= 1 << UInt64(i & 63)", "", mode="stmt"),
    Mutant("fastorder", "MaximumClique.swift", "_cliqueNumber(_simpleRows()).clique.sorted()", "_cliqueNumber(_simpleRows()).clique"),
    Mutant("lexleast", "MaximumClique.swift", "candidate.lexicographicallyPrecedes(current)", "current.lexicographicallyPrecedes(candidate)"),
    Mutant("crossprune", "MaximumClique.swift", "min(v, members.first ?? v) > current[0]", "min(v, members.first ?? v) >= current[0]"),
    Mutant("witnessreset", "MaximumClique.swift", "                        for k in 0 ..< words { witness[k] = 0 }", "", mode="stmt"),
    Mutant("openrestrict", "MaximumClique.swift", "                for k in 0 ..< words { open[k] &= sub.engine.rows[i * words + k] }", "", mode="stmt"),
    Mutant("restzero", "MaximumClique.swift", "(rest == 0 || sub.engine.search(floor: rest - 1, target: rest) >= rest)", "sub.engine.search(floor: rest - 1, target: rest) >= rest"),

    # BBMC (also Covering's and ColoringModule's)
    Mutant("bbmc_bound", "MaximumCliqueSearch.swift", "depth + colors[i] <= bestSize", "depth + colors[i] < bestSize"),
    Mutant("bbmc_colorclass", "MaximumCliqueSearch.swift", "                    for j in k ..< words { color[j] &= ~rows[v * words + j] }", "", mode="stmt"),
    Mutant("bbmc_least", "MaximumCliqueSearch.swift", "c >= least", "c > least"),
    Mutant("bbmc_child", "MaximumCliqueSearch.swift", "sets[base + k] & rows[v * words + k]", "sets[base + k]"),
    Mutant("bbmc_leaf", "MaximumCliqueSearch.swift", "                if x != 0 { empty = false }", "", mode="stmt"),
    Mutant("bbmc_greedy", "MaximumCliqueSearch.swift", "            for k in 0 ..< words { uncolored[k] &= rows[i * words + k] }", "", mode="stmt"),

    # Triangles and clustering
    Mutant("forward", "Clustering.swift", "rank[rows.targets[k]] > rank[v]", "rank[rows.targets[k]] >= rank[v]"),
    Mutant("clusteringzero", "Clustering.swift", "degree < 2", "degree < 1"),
    Mutant("transitivity", "Clustering.swift", "Double(corners) / Double(triples)", "Double(corners / 3) / Double(triples)", nth=0),
    Mutant("transitivityoneshot", "Clustering.swift", "Double(corners) / Double(triples)", "Double(corners / 3) / Double(triples)", nth=1),
    Mutant("averagezeros", "Clustering.swift", "sum / Double(triangles.count)", "sum / Double(max(triangles.filter { $0 > 0 }.count, 1))", nth=0),
    Mutant("averageoneshot", "Clustering.swift", "sum / Double(triangles.count)", "sum / Double(max(triangles.filter { $0 > 0 }.count, 1))", nth=1),
    Mutant("localseen", "Clustering.swift", "around.contains(x) && seen.insert(x).inserted", "around.contains(x)", nth=0),

    # Preconditions
    Mutant("kcore", "CoreNumbers.swift", "precondition(k >= 0, \"k must be nonnegative\")", "precondition(true, \"k must be nonnegative\")", mode="stmt", nth=0),

    # The checked: lookups.
    Mutant("clusteringchecked", "Clustering.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=0),
    Mutant("clusteringcheckedvalue", "Clustering.swift", "        return clusteringCoefficient(of: vertex)", "        return clusteringCoefficient(ofIndex: 0)", mode="stmt"),
    Mutant("trianglechecked", "Clustering.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=1),
    Mutant("trianglecheckedvalue", "Clustering.swift", "        return triangleCount(of: vertex)", "        return triangleCount(ofIndex: 3)", mode="stmt"),
    Mutant("corechecked", "CoreNumbers.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt"),
    Mutant("corecheckedvalue", "CoreNumbers.swift", "        return coreNumber(of: vertex)", "        return coreNumber(ofIndex: 0)", mode="stmt"),
]
