# Planted bugs for Similarity; run with `just mutate Similarity`. See scripts/mutate.py.
#
# Known equivalent mutants (not listed): `readsCommonNeighbors` true for preferential attachment
# (the count is computed and ignored); `u != marked` as `true` and dropping `marked = u` (every pair
# stamps its first vertex again under a fresh mark: slower, the same scores); a stamp compared with
# `>= mark` for `== mark` (marks only grow); `simple` as `true` (the ratios on merged rows: slower,
# the same scores); `change < tolerance` as `<=` (no test lands a step's change
# on the tolerance exactly); reading `_values[b * _count + a]` (the matrix is symmetric by
# construction).

TESTS = ["SimilarityTests"]

MUTANTS = [
    # The measures' formulas
    Mutant("jaccardunion", "NeighborhoodMeasures.swift", "du + dv - common", "du + dv"),
    Mutant("jaccardzero", "NeighborhoodMeasures.swift", "union == 0", "false"),
    Mutant("dicedouble", "NeighborhoodMeasures.swift", "Double(2 * common)", "Double(common)"),
    Mutant("dicezero", "NeighborhoodMeasures.swift", "total == 0", "false"),
    Mutant("cosineroot", "NeighborhoodMeasures.swift", "(Double(du) * Double(dv)).squareRoot()", "(Double(du) * Double(dv))"),
    Mutant("cosinezero", "NeighborhoodMeasures.swift", "du == 0 || dv == 0", "du == 0"),
    Mutant("adamicadarlog", "NeighborhoodMeasures.swift", "1 / log(Double(degree))", "1 / Double(degree)"),
    Mutant("resourcedegree", "NeighborhoodMeasures.swift", "1 / Double(degree)", "1 / Double(degree + 1)", nth=1),
    Mutant("attachmentproduct", "NeighborhoodMeasures.swift", "du * dv", "du + dv"),

    # One pair, with vertex indices
    Mutant("keepsloop", "NeighborhoodMeasures.swift", "w != v", "true", nth=0),
    Mutant("keepsrepeat", "NeighborhoodMeasures.swift", "kept == 0 || row[k] != row[kept - 1]", "true"),
    Mutant("unsorted", "NeighborhoodMeasures.swift", "        row.sort()", "", mode="stmt"),
    Mutant("mergestep", "NeighborhoodMeasures.swift", "a[i] < b[j]", "a[i] <= b[j]"),
    Mutant("termdegree", "NeighborhoodMeasures.swift", "measure.term(degree: _neighborSet(ofIndex: a[i]).count)", "measure.term(degree: a.count)"),

    # One pair, without vertex indices
    Mutant("setkeepsloop", "NeighborhoodMeasures.swift", "w != vertex", "true"),
    Mutant("setcommon", "NeighborhoodMeasures.swift", "a.contains(w)", "true"),
    Mutant("setmissing", "NeighborhoodMeasures.swift", "contains(u) && contains(v)", "contains(u)"),

    # Many pairs
    Mutant("checkedthrow", "NeighborhoodMeasures.swift", "                    if checked { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("checkedsecond", "NeighborhoodMeasures.swift", "!contains(u) || !contains(v)", "!contains(u)"),
    # Many pairs: the rows
    Mutant("simplechoice", "NeighborhoodMeasures.swift", "measure.sumsTerms || !measure.readsCommonNeighbors", "false"),
    Mutant("copyloop", "NeighborhoodMeasures.swift", "k &+= w == v ? 0 : 1", "k &+= 1"),
    Mutant("copymerge", "NeighborhoodMeasures.swift", "k &+= w == v || stamp[w] == v ? 0 : 1", "k &+= w == v ? 0 : 1"),

    # Many pairs: simple rows
    Mutant("simplestalemark", "NeighborhoodMeasures.swift", "                            mark &+= 1", "", mode="stmt", nth=0),
    Mutant("simplenevermark", "NeighborhoodMeasures.swift", "u != marked", "false", nth=0),
    Mutant("sumfilter", "NeighborhoodMeasures.swift", "stamps[targets[slot]] == mark", "true", nth=0),
    Mutant("sumorder", "NeighborhoodMeasures.swift", "                        if shared > 1 { common.sort() }", "", mode="stmt"),
    Mutant("sumdegree", "NeighborhoodMeasures.swift", "measure.term(degree: offsets[w &+ 1] &- offsets[w])", "measure.term(degree: dv)"),

    # Many pairs: rows with parallel copies
    Mutant("mergedstalemark", "NeighborhoodMeasures.swift", "                            mark &+= 1", "", mode="stmt", nth=1),
    Mutant("mergednevermark", "NeighborhoodMeasures.swift", "u != marked", "false", nth=1),
    Mutant("mergedudistinct", "NeighborhoodMeasures.swift", "stamps[2 &* w] != mark ? 1 : 0", "1"),
    Mutant("mergeddureset", "NeighborhoodMeasures.swift", "                            du = 0", "", mode="stmt"),
    Mutant("mergedfresh", "NeighborhoodMeasures.swift", "stamps[2 &* w &+ 1] != k", "true"),
    Mutant("mergedshared", "NeighborhoodMeasures.swift", "fresh && stamps[2 &* w] == mark", "stamps[2 &* w] == mark"),
    Mutant("onepaircheck", "LinkPrediction.swift", "        guard contains(u), contains(v) else { throw VertexNotFound() }", "        guard contains(u) else { throw VertexNotFound() }", mode="stmt", nth=1),

    # SimRank rows
    Mutant("inrowrepeats", "SimRank.swift", "slot == start[w] || sources[slot] != sources[slot - 1]", "true"),
    Mutant("neighborrepeats", "SimRank.swift", "                if stamp[w] == v { continue }", "", mode="stmt"),

    # SimRank preconditions
    Mutant("factorzero", "SimRank.swift", "importanceFactor > 0 && importanceFactor < 1", "importanceFactor >= 0 && importanceFactor < 1"),
    Mutant("factorone", "SimRank.swift", "importanceFactor > 0 && importanceFactor < 1", "importanceFactor > 0 && importanceFactor <= 1"),
    Mutant("tolerancezero", "SimRank.swift", "tolerance > 0 && tolerance.isFinite", "tolerance >= 0 && tolerance.isFinite"),
    Mutant("toleranceinfinite", "SimRank.swift", "tolerance > 0 && tolerance.isFinite", "tolerance > 0"),
    Mutant("iterationszero", "SimRank.swift", "maxIterations >= 1", "maxIterations >= 0"),

    # SimRank iteration
    Mutant("diagonal", "SimRank.swift", "    for a in 0 ..< n { similarity[a * n + a] = 1 }", "", mode="stmt"),
    Mutant("partialsum", "SimRank.swift", "s[row &+ sources[slot]]", "1"),
    Mutant("resetsums", "SimRank.swift", "                                for b in a &+ 1 ..< n { sums[b] = 0 }", "", mode="stmt"),
    Mutant("decay", "SimRank.swift", "c * sums[b]", "sums[b]"),
    Mutant("normalize", "SimRank.swift", "Double(da &* db)", "Double(da &+ db)"),
    Mutant("noinneighbor", "SimRank.swift", "db == 0", "false"),
    Mutant("nochange", "SimRank.swift", "                                    largest = max(largest, abs(value - s[row &+ b]))", "", mode="stmt"),
    Mutant("nomirror", "SimRank.swift", "                                    s[b &* n &+ a] = value", "", mode="stmt"),
    Mutant("residual", "SimRank.swift", "    throw NoConvergence(iterations: maxIterations, residual: change)", "    throw NoConvergence(iterations: maxIterations, residual: 0)", mode="stmt"),
    Mutant("skipzerorow", "SimRank.swift", "da > 0", "da >= 0"),

    # SimRankSimilarity
    Mutant("indexbound", "SimRank.swift", "j >= 0 && j < _count", "j >= 0"),
    Mutant("checkedsimrank", "SimRank.swift", "        guard _graph.contains(u), _graph.contains(v) else { throw VertexNotFound() }", "        guard _graph.contains(u) else { throw VertexNotFound() }", mode="stmt"),
]
