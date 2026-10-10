# Planted bugs for CommunityDetection; run with `just mutate CommunityDetection`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   membershipmissing  dropping the "every vertex listed" check still traps: the unlisted vertex's
#                      label −1 indexes out of range a line later (a worse message, the same trap).
#   budget             a larger marking budget before every vertex is marked: the same moves, at a
#                      different cost.
#   uniquebest         a unique most-voted label is also the greatest of the most voted, so the
#                      general tie branch gives the same label.
#
# Order matters where patterns overlap: onelevel wraps the whole stop test before threshold edits
# its condition.

TESTS = ["CommunityDetectionTests"]

MUTANTS = [
    # Membership and modularity
    Mutant("membershiptwice", "Modularity.swift", "labels[v] < 0", "true"),
    Mutant("membershipmissing", "Modularity.swift", "!labels.contains(-1)", "true"),
    Mutant("loopsonce", "Modularity.swift", "!graph.directed", "false", nth=0),
    Mutant("emptygraph", "Modularity.swift", "guard m != 0 else { return 0 }", "", nth=0, mode="stmt"),
    Mutant("emptyrows", "Modularity.swift", "guard m != 0 else { return 0 }", "", nth=1, mode="stmt"),
    Mutant("rowhalf", "Modularity.swift", "inside[c] += within / 2", "inside[c] += within", mode="stmt"),
    Mutant("rowresolution", "Modularity.swift", "resolution * degree[c] * degree[c] * norm", "degree[c] * degree[c] * norm"),
    Mutant("resolution", "Modularity.swift", "inside[c] / m - gamma * out[c] * into[c] * norm", "inside[c] / m - out[c] * into[c] * norm"),
    Mutant("directednorm", "Modularity.swift", "graph.directed ? 1 / (m * m) : 1 / ((2 * m) * (2 * m))", "1 / ((2 * m) * (2 * m))"),

    # Partition quality
    Mutant("coveragecount", "Modularity.swift", "labels[graph.from[e]] == labels[graph.to[e]]", "labels[graph.from[e]] != labels[graph.to[e]]"),
    Mutant("qualityloops", "Modularity.swift", "if a == b { continue }", "", mode="stmt"),
    Mutant("qualityrepeats", "Modularity.swift", "previous = key", "", mode="stmt"),
    Mutant("orderedpairs", "Modularity.swift", "ordered ? s * (s - 1) : s * (s - 1) / 2", "s * (s - 1) / 2"),

    # Partition
    Mutant("canonicalorder", "Partition.swift", "canonical[v] = renumber[label]", "canonical[v] = label", mode="stmt"),

    # Louvain
    Mutant("pairmerge", "Louvain.swift", "pairWeight[slot[y]] += weight(i)", "pairWeight[slot[y]] = weight(i)", mode="stmt"),
    Mutant("neighbormerge", "Louvain.swift", "weights[at] += rawWeights[slot]", "", mode="stmt"),
    Mutant("removeself", "Louvain.swift", "totalOut[current] - outDegree", "totalOut[current]"),
    Mutant("staytie", "Louvain.swift", "gain - best > tolerance || (abs(gain - best) <= tolerance && chosen != current && c > chosen)", "gain - best >= -tolerance"),
    Mutant("greatestlabel", "Louvain.swift", "gain - best > tolerance || (abs(gain - best) <= tolerance && chosen != current && c > chosen)", "gain - best > tolerance"),
    Mutant("halfgamma", "Louvain.swift", "directed ? resolution : resolution / 2", "resolution"),
    Mutant("directedgain", "Louvain.swift", "outDegree * totalIn[c] + inDegree * totalOut[c]", "outDegree * totalOut[c] + inDegree * totalIn[c]"),
    Mutant("onelevel", "Louvain.swift", "        if next - modularity <= threshold { break }", "        break", mode="stmt"),
    Mutant("threshold", "Louvain.swift", "next - modularity <= threshold", "next - modularity < 0"),
    Mutant("roundingties", "Louvain.swift", "4 * scale.ulp", "0"),
    Mutant("remarkall", "Louvain.swift", "if markedAll { for v in 0 ..< k { dirty[v] = true } }", "", mode="stmt"),
    Mutant("marknothing", "Louvain.swift", "for slot in offsets[w] ..< offsets[w + 1] { dirty[neighbors[slot]] = true }", "", mode="stmt"),
    Mutant("budget", "Louvain.swift", "marked > k + slots", "marked > 2 * (k + slots)"),
    Mutant("shuffle", "Louvain.swift", "order.swapAt(i, j)", "", mode="stmt"),

    # Greedy modularity
    Mutant("greedytie", "GreedyModularity.swift", "return u != other.u ? u < other.u : v < other.v", "return u != other.u ? u > other.u : v > other.v", mode="stmt"),
    Mutant("greedystop", "GreedyModularity.swift", "current < 0", "current <= 0"),
    Mutant("greedystale", "GreedyModularity.swift", "current == top.gain", "true"),
    Mutant("greedycommon", "GreedyModularity.swift", "d = rowV.gains[j] + rowU.gains[i]", "d = rowV.gains[j]", mode="stmt"),
    Mutant("greedyonlyv", "GreedyModularity.swift", "d = rowV.gains[j] - gamma * (au * bz + az * bu)", "d = rowV.gains[j]", mode="stmt"),
    Mutant("greedydegrees", "GreedyModularity.swift", "a[v] += a[u]", "", mode="stmt"),

    # Label propagation
    Mutant("selfvote", "LabelPropagation.swift", "            if t == u { continue }", "", mode="stmt", nth=0),
    Mutant("votesweight", "LabelPropagation.swift", "weights.map { $0[graph.edges[slot]] } ?? 1", "1"),
    Mutant("zerovote", "LabelPropagation.swift", "if x == 0 { continue }", "", mode="stmt"),
    Mutant("keeplabel", "LabelPropagation.swift", "!votes.isBest(label[u])", "true", nth=0),
    Mutant("uniquebest", "LabelPropagation.swift", "votes.best.count == 1", "false"),
    Mutant("coloring", "LabelPropagation.swift", "return a != b ? a > b : $0 < $1", "return $0 < $1", mode="stmt"),
    Mutant("greatest", "LabelPropagation.swift", "$0.max()!", "$0.min()!", nth=0),
]
