# Planted bugs for Centrality; run with `just mutate Centrality`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   grpskip        a source in the group adds nothing without `endpoints` (every pair it starts
#                  has an end in the group), so skipping it only saves its search.
#   hitsauthority  the authorities' rescale to greatest 1 each step: h = Aa is rescaled to greatest
#                  1 anyway and a is divided by its sum at the end, so only the range of the
#                  intermediate values changes (kept against overflow).
#
# Order matters where patterns overlap: harmoniclevel rewrites the in-loop level sum first, so
# harmoniclast's pattern then matches only the final one.

TESTS = ["CentralityTests"]

MUTANTS = [
    # Rows
    Mutant("transposeorder", "CentralityRows.swift", "reversedTargets[fill[w]] = v", "reversedTargets[fill[w]] = w", mode="stmt"),
    Mutant("scoreindex", "CentralityRows.swift", "return _scores[_graph._requiredVertexIndex(of: vertex, \"The vertex is not in the graph\")]", "return _scores[_scores.count - 1 - _graph._requiredVertexIndex(of: vertex, \"The vertex is not in the graph\")]", mode="stmt"),

    # Degree
    Mutant("degreesingle", "Degree.swift", "n == 1 ? 1 : Double(degree(of: $0)) * scale", "Double(degree(of: $0)) * scale"),
    Mutant("indegree", "Degree.swift", "for v in 0 ..< n { for w in successorIndices(ofIndex: v) { counts[w] += 1 } }", "", mode="stmt"),
    Mutant("indegreelisted", "Degree.swift", "for position in edges.indices { counts[numbers[target(ofEdgeAt: position)]!] += 1 }", "", mode="stmt"),
    Mutant("outdegree", "Degree.swift", "counts = (0 ..< n).map { outDegree(ofIndex: $0) }", "counts = [Int](repeating: 0, count: n)", mode="stmt"),
    Mutant("outdegreelisted", "Degree.swift", "counts = vertices.map { outDegree(of: $0) }", "counts = [Int](repeating: 0, count: n)", mode="stmt"),
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

    # Betweenness from pivots
    Mutant("pivotsources", "Betweenness.swift", "pivots ?? Array(0 ..< n)", "Array(0 ..< n)", nth=0),
    Mutant("pivotsourcesweighted", "Betweenness.swift", "pivots ?? Array(0 ..< n)", "Array(0 ..< n)", nth=1),
    Mutant("pivotround", "Betweenness.swift", "round * (n + 1) + 1", "1"),
    Mutant("pivotcount", "Betweenness.swift", "endpoints ? scores.count : scores.count - 1", "scores.count"),
    Mutant("pivotother", "Betweenness.swift", "1 / (k * (n - 1))", "1 / (k * n)", nth=0),
    Mutant("pivototherraw", "Betweenness.swift", "n / (k * correction)", "n / k"),
    Mutant("pivotendpoints", "Betweenness.swift", "!endpoints", "true"),
    Mutant("pivotown", "Betweenness.swift", "1 / ((k - 1) * (n - 1))", "1 / (k * (n - 1))"),
    Mutant("pivotownraw", "Betweenness.swift", "n / ((k - 1) * correction)", "n / (k * correction)"),
    Mutant("pivotmatch", "Betweenness.swift", "pivots[next] == v", "false"),
    Mutant("randomdraw", "Betweenness.swift", "i + Int(generator.next(upperBound: UInt(n - i)))", "Int(generator.next(upperBound: UInt(n)))"),
    Mutant("randomcount", "Betweenness.swift", "k >= 0 && k <= n && (k > 0 || n == 0)", "k <= n"),
    Mutant("pivotrepeat", "Betweenness.swift", "precondition(!chosen[v], \"A pivot is repeated\")", "", mode="stmt"),
    Mutant("pivotnone", "Betweenness.swift", "precondition(k > 0 || n == 0, \"There must be at least one pivot\")", "", mode="stmt"),

    # Edge betweenness
    Mutant("edgesource", "EdgeBetweenness.swift", "k >= 0", "k > 0", nth=0),
    Mutant("edgesourceweighted", "EdgeBetweenness.swift", "k >= 0", "k > 0", nth=1),
    Mutant("edgedependency", "EdgeBetweenness.swift", "sv / sigma[w] * (1 + delta[w])", "sv / sigma[w]", nth=0),
    Mutant("edgedependencyweighted", "EdgeBetweenness.swift", "sv / sigma[w] * (1 + delta[w])", "sv / sigma[w]", nth=1),
    Mutant("edgedelta", "EdgeBetweenness.swift", "dependency += c", "", nth=0, mode="stmt"),
    Mutant("edgedeltaweighted", "EdgeBetweenness.swift", "dependency += c", "", nth=1, mode="stmt"),
    Mutant("edgereset", "EdgeBetweenness.swift", "for k in 0 ..< tail { distance[order[k]] = -1 }", "", mode="stmt"),
    Mutant("edgesigmatie", "EdgeBetweenness.swift", "distance[w] == next", "false", nth=0),
    Mutant("edgesigmatieweighted", "EdgeBetweenness.swift", "candidate == distance[w]", "false"),
    Mutant("edgesettle", "EdgeBetweenness.swift", "stamp[w] > mark", "true"),
    Mutant("edgeround", "EdgeBetweenness.swift", "        round += 1", "", mode="stmt"),
    Mutant("edgepivots", "EdgeBetweenness.swift", "pivots ?? Array(0 ..< n)", "Array(0 ..< n)", nth=0),
    Mutant("edgepivotsweighted", "EdgeBetweenness.swift", "pivots ?? Array(0 ..< n)", "Array(0 ..< n)", nth=1),
    Mutant("edgesmall", "EdgeBetweenness.swift", "guard vertexCount >= 2 else { return }", "", mode="stmt"),
    Mutant("edgenormalized", "EdgeBetweenness.swift", "1 / (k * (n - 1))", "1 / (k * n)"),
    Mutant("edgehalving", "EdgeBetweenness.swift", "n / (k * (directed ? 1 : 2))", "n / k"),
    Mutant("edgeidentityfirst", "EdgeBetweenness.swift", "unsafeBitCast(first, to: Int.self) == 0", "true"),
    Mutant("edgeidentitylast", "EdgeBetweenness.swift", "unsafeBitCast(positions[positions.count - 1], to: Int.self) == positions.count - 1", "true"),
    Mutant("edgenumberrange", "EdgeBetweenness.swift", "e >= 0 && e < _scores.count ? e : nil", "e"),
    Mutant("edgesearchmember", "EdgeBetweenness.swift", "low < _positions.count && _positions[low] == position ? low : nil", "low < _positions.count ? low : nil"),
    Mutant("edgesearchstep", "EdgeBetweenness.swift", "if _positions[mid] < position { low = mid + 1 } else { high = mid }", "if _positions[mid] <= position { low = mid + 1 } else { high = mid }", mode="stmt"),

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
    # NoConvergence: the residual (the last change over n), per measure
    Mutant("eigenresidual", "PowerIteration.swift", "change / Double(n)", "change", nth=0),
    Mutant("katzresidual", "PowerIteration.swift", "change / Double(n)", "change", nth=1),
    Mutant("pagerankresidual", "PowerIteration.swift", "change / Double(n)", "change", nth=2),
    Mutant("hitsresidual", "PowerIteration.swift", "change / Double(n)", "change", nth=3),
    Mutant("hitslastchange", "PowerIteration.swift", "        change = step", "", mode="stmt"),
    Mutant("weightsread", "PowerIteration.swift", "edges.map { Double(weights[$0]) }", "edges.map { _ in 1.0 }"),

    # The checked: lookups.
    Mutant("scorechecked", "CentralityRows.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt"),
    Mutant("scorecheckedvalue", "CentralityRows.swift", "        return score(of: vertex)", "        return score(ofIndex: 0)", mode="stmt"),

    # The shortest-path DAG, load and percolation.
    Mutant("dagparents", "ShortestPathDAG.swift", "parents[w] += 1", "", nth=0, mode="stmt"),
    Mutant("dagreset", "ShortestPathDAG.swift", "for k in 0 ..< reached { hops[order[k]] = -1 }", "", mode="stmt"),
    Mutant("dagweightedstep", "ShortestPathDAG.swift", "stamp[w] > stamp[v] && stamp[w] > base && distance[w] == distance[v] + weights[slot]", "distance[w] == distance[v] + weights[slot]"),
    Mutant("dagtie", "ShortestPathDAG.swift", "parents[w] += 1", "", nth=1, mode="stmt"),
    Mutant("loadshare", "Load.swift", "through += (1 + passed[w]) / Double(dag.parents[w])", "through += (1 + passed[w]) * dag.sigma[v] / dag.sigma[w]", mode="stmt"),
    Mutant("loadscale", "Load.swift", "guard normalized, scores.count > 2 else { return }", "guard scores.count > 2 else { return }", mode="stmt"),
    Mutant("percstate", "Load.swift", "if others > 0 { result[v] += dependency * states[s] / others }", "result[v] += dependency", mode="stmt"),
    Mutant("percscale", "Load.swift", "1 / Double(scores.count - 2)", "1 / Double(scores.count - 1)"),
    Mutant("percrange", "Load.swift", "x >= 0 && x <= 1", "true"),

    # Group centrality.
    Mutant("grpavoid", "GroupCentrality.swift", "guard k == 0 || !group[v] else { continue }", "", mode="stmt"),
    Mutant("grpends", "GroupCentrality.swift", "if endpoints { sum += 1 }", "", mode="stmt"),
    Mutant("grpskip", "GroupCentrality.swift", "if !endpoints, group[s] { continue }", "", mode="stmt"),
    Mutant("grpsize", "GroupCentrality.swift", "Double(endpoints ? n : n - k)", "Double(n)"),
    Mutant("grphalf", "GroupCentrality.swift", "return directed ? sum : sum / 2", "return sum", mode="stmt"),
    Mutant("grpclosezero", "GroupCentrality.swift", "return total > 0 ? Double(outside) / total : 0", "return Double(outside) / total", mode="stmt"),
    Mutant("grpclosereverse", "GroupCentrality.swift", "return _groupCloseness(rows.transposed(), group: flags, slotWeights: nil)", "return _groupCloseness(rows, group: flags, slotWeights: nil)", mode="stmt"),
    Mutant("grpdegreemark", "GroupCentrality.swift", "marked[rows.targets[slot]] = true", "", mode="stmt"),
    Mutant("grprepeat", "GroupCentrality.swift", "!flags[i]", "true", nth=0),
    Mutant("grpfull", "GroupCentrality.swift", "size < vertexCount", "true", nth=0),

    # Current flow.
    Mutant("cfends", "CurrentFlow.swift", "for v in 0 ..< n { result[v] -= ends }", "", mode="stmt"),
    Mutant("cfrank", "CurrentFlow.swift", "sum += r[i] * Double(2 * i - (n - 1))", "sum += r[i] * Double(i)", mode="stmt"),
    Mutant("cfconductance", "CurrentFlow.swift", "for i in 0 ..< n { r[i] = c * (inverse[u * n + i] - inverse[v * n + i]) }", "for i in 0 ..< n { r[i] = inverse[u * n + i] - inverse[v * n + i] }", mode="stmt"),
    Mutant("cfsingular", "CurrentFlow.swift", "if !(d > 1e-12 * largest) { return true }", "", mode="stmt"),
    Mutant("cfmerge", "CurrentFlow.swift", "weights[slotOf[w]] += x", "", mode="stmt"),
    Mutant("cfnormalize", "CurrentFlow.swift", "normalized ? 2 / (Double(n - 1) * Double(n - 2)) : 1", "normalized ? 1 / (Double(n - 1) * Double(n - 2)) : 1"),
    Mutant("cfcloseness", "CurrentFlow.swift", "total += inverse[v * n + v] + inverse[w * n + w] - 2 * inverse[v * n + w]", "total += inverse[v * n + v] - inverse[v * n + w]", mode="stmt"),

    # Communicability and VoteRank.
    Mutant("expsquare", "Communicability.swift", "        s += 1", "", mode="stmt"),
    Mutant("expterms", "Communicability.swift", "1 ... 18", "1 ... 3"),
    Mutant("expscale", "Communicability.swift", "norm * scale > 0.5", "norm * scale > 8"),
    Mutant("commsymmetric", "Communicability.swift", "return _values[i * _count + j]", "return _values[i * _count + i]", mode="stmt"),
    Mutant("vrweaken", "VoteRank.swift", "ability[w] = max(0, ability[w] - 1 / averageDegree)", "", mode="stmt"),
    Mutant("vrfloor", "VoteRank.swift", "ability[w] = max(0, ability[w] - 1 / averageDegree)", "ability[w] = ability[w] - 1 / averageDegree", mode="stmt"),
    Mutant("vrtie", "VoteRank.swift", "score > most", "score >= most && score > 0"),
    Mutant("vrchosen", "VoteRank.swift", "ability[best] = 0", "", mode="stmt"),
]
