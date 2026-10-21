# Planted bugs for ParallelCentrality; run with `just mutate ParallelCentrality`. See
# scripts/mutate.py.
#
# Not planted: dropping the `tasks == 1` shortcuts (the task group gives the same sums), and
# dropping the cap of the task count at the source count (the extra shares are empty).

TESTS = ["ParallelCentralityTests"]

PM = "Parallelism.swift"
PB = "ParallelBetweenness.swift"
PC = "ParallelCloseness.swift"

MUTANTS = [
    # Task count.
    Mutant("taskcheck", PM, "requested > 0", "requested >= 0"),
    # Shares: every source once, in every share's stride.
    Mutant("sumstride", PM, "stride(from: k, to: n, by: tasks)", "stride(from: k, to: n, by: tasks + 1)", nth=0),
    Mutant("sumorder", PM, "parts[k] = part", "parts[parts.firstIndex(where: { $0 == nil })!] = part"),
    Mutant("sumadd", PM, "total[v] += part[v]", "total[v] = part[v]"),
    Mutant("gatherstride", PM, "stride(from: k, to: n, by: tasks)", "stride(from: k, to: n, by: tasks + 1)", nth=1),
    Mutant("gatherstart", PM, "stride(from: k, to: n, by: tasks)", "stride(from: 0, to: n, by: tasks)", nth=1),
    Mutant("gatherstep", PM, "source += tasks", "source += 1"),
    # The measures.
    Mutant("btwrescale", PB, "_rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)", "_rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)", nth=0),
    Mutant("btwendpoints", PB, "_betweenness(rows, pivots: sources, endpoints: endpoints)", "_betweenness(rows, pivots: sources, endpoints: false)", nth=0),
    Mutant("btwweights", PB, "_betweenness(rows, slotWeights: weights, pivots: sources, endpoints: endpoints)", "_betweenness(rows, pivots: sources, endpoints: endpoints)", nth=1),
    Mutant("btwdirected", PB, "_rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: true)", "_rescaleBetweenness(&scores, normalized: normalized, endpoints: endpoints, directed: false)", nth=1),
    Mutant("closewf", PC, "_closeness(reached: r, total: total, count: n, wfImproved: wfImproved)", "_closeness(reached: r, total: total, count: n, wfImproved: true)"),
    Mutant("closecount", PC, "_closeness(reached: r, total: total, count: n, wfImproved: wfImproved)", "_closeness(reached: r, total: total, count: sources.count, wfImproved: wfImproved)"),
    Mutant("harmonictotal", PC, "sources.map { search.sums(from: $0).harmonic }", "sources.map { search.sums(from: $0).total }"),
    Mutant("closetransposed", PC, "copied.transposed()", "copied", nth=0),
]
