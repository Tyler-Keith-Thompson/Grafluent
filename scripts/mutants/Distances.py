# Planted bugs for Distances; run with `just mutate Distances`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   directedstop  without the early stop, pruning still settles a graph that is not strongly
#                 connected in a few searches (every vertex a missing search reached is skipped).

TESTS = ["DistancesTests"]

MUTANTS = [
    # Rows and weights
    Mutant("selfloop", "DistanceRows.swift", "                if w == v { continue }", "", mode="stmt", nth=0),
    Mutant("weightsign", "DistanceRows.swift", "w >= .zero && w == w", "w == w", nth=0),
    Mutant("weightnan", "DistanceRows.swift", "w >= .zero && w == w", "w >= .zero || w != w", nth=1),

    # Breadth-first search
    Mutant("bfsreset", "DistanceRows.swift", "                            for k in 0 ..< reached { distanceBuffer[queueBuffer[k]] = -1 }", "", mode="stmt"),
    Mutant("bfstotal", "DistanceRows.swift", "                                        total += next", "", mode="stmt"),
    Mutant("bfsreachedall", "DistanceRows.swift", "reached == n", "reached >= n - 1"),

    # Dijkstra
    Mutant("dijkstradecrease", "DistanceRows.swift", "candidate < distance[w]", "false"),
    Mutant("dijkstraeccentricity", "DistanceRows.swift", "            if d > eccentricity { eccentricity = d }", "", mode="stmt"),
    Mutant("dijkstrareached", "DistanceRows.swift", "settled == rows.count", "settled >= rows.count - 1"),

    # Bounding
    Mutant("lowerbound", "Extrema.swift", "max(lower[i], max(d, e - d))", "max(lower[i], d)"),
    Mutant("diameterrule", "Extrema.swift", "up <= maxLower && 2 * low >= maxUpper", "up <= maxLower"),
    Mutant("radiusrule", "Extrema.swift", "low >= minUpper && up + 1 <= 2 * minLower", "low >= minUpper"),
    Mutant("peripheryrule", "Extrema.swift", "up < maxLower && (maxLower == maxUpper || low > maxUpper)", "up <= maxLower"),
    Mutant("centerrule", "Extrema.swift", "low > minUpper && (minLower == minUpper || up + 1 < 2 * minLower)", "low >= minUpper"),
    Mutant("boundingdisconnected", "Extrema.swift", "        guard reachedAll else { return nil }", "", mode="stmt", nth=0),

    # All-sources searches and pruning
    Mutant("undirectedmiss", "Extrema.swift", "rows.undirected || stopAtMiss", "stopAtMiss", nth=0),
    Mutant("pruning", "Extrema.swift", "        for v in searches.reachedVertices { known[v] = true }", "        for v in searches.reachedVertices.prefix(2) { known[v] = true }", mode="stmt", nth=0),
    Mutant("radiusinfinite", "Extrema.swift", "infinite ? nil : diameter", "diameter"),
    Mutant("leasttotal", "Extrema.swift", "if least.map({ t < $0 }) ?? true { least = t }", "if least.map({ t > $0 }) ?? true { least = t }", mode="stmt"),
    Mutant("wienerhalf", "Extrema.swift", "rows.undirected ? s + 1 : 0", "0", nth=0),
    Mutant("pairs", "Extrema.swift", "undirected ? n * (n - 1) / 2 : n * (n - 1)", "n * (n - 1)"),

    # Measures
    Mutant("pathstart", "Measures.swift", "bounds.lower.firstIndex(of: bounds.maxLower)!", "bounds.lower.lastIndex(of: bounds.maxLower)!"),
    Mutant("pathend", "Measures.swift", "searches.distance.firstIndex(of: bounds.maxLower)!", "searches.distance.lastIndex(of: bounds.maxLower)!"),
    Mutant("weightedfarthest", "Measures.swift", "searches.distance[x] > searches.distance[v]", "searches.distance[x] >= searches.distance[v]"),
    Mutant("averageone", "Measures.swift", "n == 1 ? 0 : Double(total) / Double(_pairCount(n, undirected: true))", "Double(total) / Double(max(_pairCount(n, undirected: true), 1)) + (n == 1 ? 1 : 0)"),
    Mutant("density", "Measures.swift", "2 * Double(edgeCount) / (Double(n) * Double(n - 1))", "Double(edgeCount) / (Double(n) * Double(n - 1))"),
    Mutant("directeddensity", "DirectedMeasures.swift", "Double(edgeCount) / (Double(n) * Double(n - 1))", "2 * Double(edgeCount) / (Double(n) * Double(n - 1))"),
    Mutant("directedstop", "DirectedMeasures.swift", "_allEccentricities(rows, stopAtMiss: true)", "_allEccentricities(rows)", nth=0),
    Mutant("center", "Eccentricities.swift", "_matching(_values, _radius)", "_matching(_values, _diameter)"),
]
