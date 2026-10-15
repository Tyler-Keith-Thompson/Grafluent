# Planted bugs for Distances; run with `just mutate Distances`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   directedstop  without the early stop, pruning still settles a graph that is not strongly
#                 connected in a few searches (every vertex a missing search reached is skipped).
#   selfloop, selfloopdirected
#                 a self-loop is on no shortest path, so keeping it in the rows changes nothing.
#   diameterrule, radiusrule, undirectedmiss, pruning
#                 each removes a shortcut (a goal's rule-out, the stop at the first miss, the
#                 skip of vertices a missing search reached): the answers are the same, only the
#                 number of searches grows. The benchmarks show the difference.

TESTS = ["DistancesTests"]

MUTANTS = [
    # Rows and weights
    Mutant("selfloop", "DistanceRows.swift", "_CopyRows(readsEdges: true, dropsLoops: true)", "_CopyRows(readsEdges: true, dropsLoops: false)"),
    Mutant("selfloopdirected", "DistanceRows.swift", "_compressedRows(readsEdges: true, dropsLoops: true)", "_compressedRows(readsEdges: true, dropsLoops: false)"),
    Mutant("weightsign", "DistanceRows.swift", "$0 >= .zero && $0 == $0", "$0 == $0", nth=0),
    Mutant("weightnan", "DistanceRows.swift", "$0 >= .zero && $0 == $0", "$0 >= .zero || $0 != $0", nth=0),
    Mutant("weightsigndirected", "DistanceRows.swift", "$0 >= .zero && $0 == $0", "$0 == $0", nth=1),
    Mutant("weightnandirected", "DistanceRows.swift", "$0 >= .zero && $0 == $0", "$0 >= .zero || $0 != $0", nth=1),

    # Breadth-first search
    Mutant("bfsreset", "DistanceRows.swift", "                            for k in 0 ..< reached { distanceBuffer[queueBuffer[k]] = -1 }", "", mode="stmt"),
    Mutant("bfstotal", "DistanceRows.swift", "                                        total += Int64(next)", "", mode="stmt"),
    Mutant("bfsreachedall", "DistanceRows.swift", "reached == n", "reached >= n - 1"),

    # Dijkstra
    Mutant("dijkstradecrease", "DistanceRows.swift", "candidate < distance[w]", "false"),
    Mutant("dijkstraeccentricity", "DistanceRows.swift", "            if d > eccentricity { eccentricity = d }", "", mode="stmt"),
    Mutant("dijkstrareached", "DistanceRows.swift", "settled == rows.count", "settled >= rows.count - 1"),

    # Bounding
    Mutant("lowerbound", "Extrema.swift", "                                if e - d > low { low = e - d }", "", mode="stmt"),
    Mutant("upperbound", "Extrema.swift", "                                if e + d < up { up = e + d }", "", mode="stmt"),
    Mutant("selection", "Extrema.swift", "low < lm || (low == lm && degree[i] > degree[minLowerVertex])", "false"),
    Mutant("diameterrule", "Extrema.swift", "up <= maxLower && 2 * low >= maxUpper", "up <= maxLower"),
    Mutant("radiusrule", "Extrema.swift", "low >= minUpper && up + 1 <= 2 * minLower", "low >= minUpper"),
    Mutant("peripheryrule", "Extrema.swift", "up < maxLower && (maxLower == maxUpper || low > maxUpper)", "up <= maxLower"),
    Mutant("centerrule", "Extrema.swift", "low > minUpper && (minLower == minUpper || up + 1 < 2 * minLower)", "low >= minUpper"),
    Mutant("boundingdisconnected", "Extrema.swift", "        guard reachedAll else { return nil }", "", mode="stmt", nth=0),

    # All-sources searches and pruning
    Mutant("undirectedmiss", "Extrema.swift", "undirected || stopAtMiss", "stopAtMiss", nth=0),
    Mutant("pruning", "Extrema.swift", "        for v in searches.reachedVertices { known[v] = true }", "        for v in searches.reachedVertices.prefix(2) { known[v] = true }", mode="stmt", nth=0),
    Mutant("radiusinfinite", "Extrema.swift", "infinite ? nil : diameter", "diameter"),
    Mutant("leasttotal", "Extrema.swift", "if least.map({ t < $0 }) ?? true { least = t }", "if least.map({ t > $0 }) ?? true { least = t }", mode="stmt"),
    Mutant("wienerhalf", "Extrema.swift", "undirected ? total / 2 : total", "total"),
    Mutant("wienerweightedhalf", "Extrema.swift", "undirected ? s + 1 : 0", "0", nth=0),
    Mutant("pairs", "Extrema.swift", "Double(n) * Double(n - 1) / (undirected ? 2 : 1)", "Double(n) * Double(n - 1)"),

    # Measures
    Mutant("pathstart", "Measures.swift", "bounds.lower.firstIndex(of: bounds.maxLower)!", "bounds.lower.lastIndex(of: bounds.maxLower)!"),
    Mutant("pathend", "Measures.swift", "searches.distance.firstIndex(of: bounds.maxLower)!", "searches.distance.lastIndex(of: bounds.maxLower)!"),
    Mutant("weightedfarthest", "Measures.swift", "searches.distance[x] > searches.distance[v]", "searches.distance[x] >= searches.distance[v]"),
    Mutant("averageone", "Measures.swift", "n == 1 ? 0 : Double(total) / _pairCount(n, undirected: true)", "Double(total) / max(_pairCount(n, undirected: true), 1) + (n == 1 ? 1 : 0)"),
    Mutant("density", "Measures.swift", "2 * Double(edgeCount) / (Double(n) * Double(n - 1))", "Double(edgeCount) / (Double(n) * Double(n - 1))"),
    Mutant("directeddensity", "DirectedMeasures.swift", "Double(edgeCount) / (Double(n) * Double(n - 1))", "2 * Double(edgeCount) / (Double(n) * Double(n - 1))"),
    Mutant("directedstop", "DirectedMeasures.swift", "_allEccentricities(rows, undirected: false, stopAtMiss: true)", "_allEccentricities(rows, undirected: false)", nth=0),
    Mutant("center", "Eccentricities.swift", "_matching(_values, _radius)", "_matching(_values, _diameter)"),

    # The checked: lookups.
    Mutant("eccentricitychecked", "Eccentricities.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt"),
    Mutant("eccentricitycheckedvalue", "Eccentricities.swift", "        return eccentricity(of: vertex)", "        return eccentricity(ofIndex: 0)", mode="stmt"),

    # Global and local efficiency.
    Mutant("effdepth", "Efficiency.swift", "            sum += Double(atDepth[d]) / Double(d)", "            sum += Double(atDepth[d])", mode="stmt"),
    Mutant("effreset", "Efficiency.swift", "            atDepth[d] = 0", "", mode="stmt"),
    Mutant("effglobalnorm", "Efficiency.swift", "(Double(n) * Double(n - 1))", "Double(n * n)"),
    Mutant("efflocalnorm", "Efficiency.swift", "(Double(k) * Double(k - 1))", "Double(k * k)"),
    Mutant("efflocalstamp", "Efficiency.swift", "stamp[rows.targets[inner]] == v", "true"),
    Mutant("efflocalmean", "Efficiency.swift", "total / Double(n)", "total / Double(max(n - 1, 1))"),
]
