# Planted bugs for Centrality; run with `just mutate Centrality`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   hitsauthority  the authorities' rescale to greatest 1 each step: h = Aa is rescaled to greatest
#                  1 anyway and a is divided by its sum at the end, so only the range of the
#                  intermediate values changes (kept, as NetworkX does, against overflow).
#
# Order matters where patterns overlap: harmoniclevel rewrites the in-loop level sum first, so
# harmoniclast's pattern then matches only the final one.

TESTS = ["CentralityTests"]

MUTANTS = [
    # Rows
    Mutant("transposeorder", "CentralityRows.swift", "reversedTargets[fill[w]] = v", "reversedTargets[fill[w]] = w", mode="stmt"),
    Mutant("scoreindex", "CentralityRows.swift", "return _scores[_graph.vertexIndex(of: vertex)]", "return _scores[_scores.count - 1 - _graph.vertexIndex(of: vertex)]", mode="stmt"),

    # Degree
    Mutant("degreesingle", "Degree.swift", "n == 1 ? 1 : Double(degree(of: $0)) * scale", "Double(degree(of: $0)) * scale"),
    Mutant("indegree", "Degree.swift", "for v in 0 ..< n { for w in successorIndices(ofIndex: v) { counts[w] += 1 } }", "", mode="stmt"),
    Mutant("indegreelisted", "Degree.swift", "for position in edges.indices { counts[numbers[target(ofEdgeAt: position)]!] += 1 }", "", mode="stmt"),
    Mutant("outdegree", "Degree.swift", "outgoing ? vertices.map { outDegree(of: $0) } : [Int](repeating: 0, count: n)", "[Int](repeating: 0, count: n)"),
    Mutant("degreescale", "Degree.swift", "1 / Double(n - 1)", "1 / Double(n)", nth=0),

    # Searches
    Mutant("bfsreset", "Searches.swift", "for k in 0 ..< reached { distanceBuffer[queueBuffer[k]] = -1 }", "", mode="stmt"),
    Mutant("harmoniclevel", "Searches.swift", "harmonic += Double(atDepth) / Double(depth)", "harmonic += 1 / Double(depth)", nth=0, mode="stmt"),
    Mutant("harmoniclast", "Searches.swift", "if depth > 0 { harmonic += Double(atDepth) / Double(depth) }", "", mode="stmt"),
    Mutant("harmonicweighted", "Searches.swift", "x > 0", "x >= 0"),
    Mutant("dijkstradecrease", "Searches.swift", "candidate < distance[w]", "false"),
    Mutant("closenesswf", "Searches.swift", "closeness * (Double(r - 1) / Double(n - 1))", "closeness"),
    Mutant("closenesszero", "Searches.swift", "total > 0", "true"),

    # Betweenness
    Mutant("sigmaparallel", "Betweenness.swift", "if distance[w] == next { sigma[w] += sv }", "if distance[w] == next, sigma[w] == 0 { sigma[w] += sv }", mode="stmt"),
    Mutant("sigmareset", "Betweenness.swift", "                                        sigma[v] = 0", "", mode="stmt"),
    Mutant("dependency", "Betweenness.swift", "sv / sigma[w] * (1 + delta[w])", "sv / sigma[w] * delta[w]", nth=0),
    Mutant("dependencyweighted", "Betweenness.swift", "sv / sigma[w] * (1 + delta[w])", "sv / sigma[w] * delta[w]", nth=1),
    Mutant("endpointsource", "Betweenness.swift", "if endpoints { result[s] += Double(tail - 1) }", "", mode="stmt"),
    Mutant("endpointtarget", "Betweenness.swift", "endpoints ? dependency + 1 : dependency", "dependency", nth=0),
    Mutant("weightedtie", "Betweenness.swift", "                        sigma[w] += sv", "", mode="stmt"),
    Mutant("weightedreset", "Betweenness.swift", "sigma[w] = sv", "", nth=1, mode="stmt"),
    Mutant("settlerank", "Betweenness.swift", "stamp[w] > mark", "true"),
    Mutant("halving", "Betweenness.swift", "scale = 0.5", "scale = 1", mode="stmt"),
    Mutant("directedhalving", "Betweenness.swift", "guard !directed else { return }", "", mode="stmt"),
    Mutant("smallscale", "Betweenness.swift", "guard scores.count > 2 else { return }", "", mode="stmt"),
    Mutant("endpointscale", "Betweenness.swift", "1 / (n * (n - 1))", "1 / ((n - 1) * (n - 2))"),

    # Power iterations
    Mutant("eigenshift", "PowerIteration.swift", "y[i] = x[i]", "y[i] = 0", mode="stmt"),
    Mutant("eigennorm", "PowerIteration.swift", "norm = norm.squareRoot()", "", nth=0, mode="stmt"),
    Mutant("stoprule", "PowerIteration.swift", "Double(n) * tolerance", "tolerance", nth=0),
    Mutant("katzbeta", "PowerIteration.swift", "y[i] = alpha * y[i] + beta", "y[i] = alpha * y[i] + 1", mode="stmt"),
    Mutant("katznormalize", "PowerIteration.swift", "norm > 0", "false"),
    Mutant("dangling", "PowerIteration.swift", "y[i] = d * (y[i] + danglingMass * p[i]) + (1 - d) * p[i]", "y[i] = d * y[i] + (1 - d) * p[i]", mode="stmt"),
    Mutant("pagerankscale", "PowerIteration.swift", "share[i] = x[i] * scale[i]", "share[i] = x[i]", mode="stmt"),
    Mutant("personalization", "PowerIteration.swift", "values.map { $0 / total }", "values"),
    Mutant("hitsedgeless", "PowerIteration.swift", "greatestHub > 0", "true"),
    Mutant("hitsnormalize", "PowerIteration.swift", "                h[i] /= hubTotal", "", mode="stmt"),
    Mutant("hitsauthority", "PowerIteration.swift", "a[i] *= 1 / greatestAuthority", "", mode="stmt"),
    Mutant("weightsread", "PowerIteration.swift", "edges.map { Double(weights[$0]) }", "edges.map { _ in 1.0 }"),
]
