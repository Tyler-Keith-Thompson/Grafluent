# Planted bugs for CommunityDetection; run with `just mutate CommunityDetection`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   membershipmissing  dropping the "every vertex listed" check still traps: the unlisted vertex's
#                      label −1 indexes out of range a line later (a worse message, the same trap).
#   budget             a larger marking budget before every vertex is marked: the same moves, at a
#                      different cost.
#   uniquebest         a unique most-voted label is also the greatest of the most voted, so the
#                      general tie branch gives the same label.
#   klupdate           pushing an unchanged value adds an entry with a later stamp; the older entry
#                      with the same value is popped first, and the newer is then stale.
#   klcount            without the two-community check, a third community's side is −1 and
#                      indexes out of range a line later: the same trap with a worse message.
#   sccount            spectral clustering without the upper bound on the cluster count still traps:
#                      the eigenpairs' count precondition (at most vertexCount) fires next.
#
# Planted and surviving, not equivalent (open):
#   kmempty            k-means' empty-cluster relocation. k-means++ seeds are distinct rows and a
#                      seed's own row is at distance 0, so the first assignment never empties a
#                      cluster; no later Lloyd step emptied one in 15,000 seeded clusterings of random
#                      graphs of 10 to 40 vertices (k = 3 … 8) nor in 12,000 of 4 to 11 vertices.
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
    Mutant("onelevel", "Louvain.swift", "if next - modularity <= threshold { return (labels, next, nil) }", "return (labels, next, nil)", mode="stmt"),
    Mutant("threshold", "Louvain.swift", "next - modularity <= threshold", "next - modularity < 0"),
    Mutant("roundingties", "Louvain.swift", "4 * scale.ulp", "0"),
    Mutant("remarkall", "Louvain.swift", "if markedAll { for v in 0 ..< k { dirty[v] = true } }", "", mode="stmt"),
    Mutant("marknothing", "Louvain.swift", "for slot in offsets[w] ..< offsets[w + 1] { dirty[neighbors[slot]] = true }", "", mode="stmt"),
    Mutant("budget", "Louvain.swift", "marked > k + slots", "marked > 2 * (k + slots)"),
    Mutant("shuffle", "Louvain.swift", "order.swapAt(i, j)", "", mode="stmt"),
    # Louvain as an event sequence
    Mutant("lvgain", "Louvain.swift", "(best - stay) / (m * m)", "best / (m * m)"),
    Mutant("lveaggregate", "LouvainEvents.swift", "pending.append(.aggregate(vertexCount: k))", "", mode="stmt"),
    Mutant("lvemoved", "LouvainEvents.swift", "run!.moved ? 1 : 3", "1"),
    Mutant("lveorder", "LouvainEvents.swift", "Array(0 ..< k)", "Array((0 ..< k).reversed())"),

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

    # Girvan–Newman
    Mutant("gntie", "GirvanNewman.swift", "lhs.score == rhs.score && lhs.edge < rhs.edge", "lhs.score == rhs.score && lhs.edge > rhs.edge"),
    Mutant("gnleast", "GirvanNewman.swift", "lhs.score > rhs.score", "lhs.score < rhs.score"),
    Mutant("gnconnected", "GirvanNewman.swift", "_seen[v] == _round", "false"),
    Mutant("gnstale", "GirvanNewman.swift", "_recompute(listed, component: c)", "", nth=0, mode="stmt"),
    Mutant("gnsplitside", "GirvanNewman.swift", "_recompute(listed, component: c)", "", nth=1, mode="stmt"),
    Mutant("gnsplitnew", "GirvanNewman.swift", "_recompute(listed, component: split)", "", mode="stmt"),
    Mutant("gnzero", "GirvanNewman.swift", "for slot in _starts[v] ..< _ends[v] { _scores[_edges[slot]] = 0 }", "", mode="stmt"),
    Mutant("gnotherend", "GirvanNewman.swift", "_removeEnd(2 * e + 1)", "", mode="stmt"),
    Mutant("gnmoved", "GirvanNewman.swift", "_slotOfEnd[moved] = slot", "", mode="stmt"),
    Mutant("gnedgeless", "GirvanNewman.swift", "if _central.isEmpty { return _partition() }", "", mode="stmt"),
    Mutant("gnlabel", "GirvanNewman.swift", "for w in listed { _component[w] = split }", "", mode="stmt"),
    Mutant("gncount", "GirvanNewman.swift", "                _componentCount += 1", "", nth=1, mode="stmt"),
    Mutant("gnbest", "GirvanNewman.swift", "best.map({ candidate < $0 }) ?? true", "best == nil"),

    # community(checked:).
    Mutant("ckcommunitylookup", "Partition.swift", "_numbers[vertex]", "Optional(_numbers[vertex] ?? 0)", nth=1),
    Mutant("ckcommunityvalue", "Partition.swift", "return _labels[v]", "return 0", mode="stmt", nth=1),
    Mutant("ckcommunityguard", "Partition.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("ckcommunitythrow", "Partition.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "throw VertexNotFound()", mode="stmt"),

    # Leiden.
    Mutant("ldemptychoice", "Leiden.swift", "-best > tolerance", "false"),
    Mutant("ldstaybias", "Leiden.swift", "gain - best > tolerance", "gain - best > -tolerance"),
    Mutant("ldtotals", "Leiden.swift", "totalA[chosen] += av", "", mode="stmt"),
    Mutant("ldownpenalty", "Leiden.swift", "gamma * (av * ownB + bv * ownA)", "gamma * (av * totalB[current] + bv * totalA[current])"),
    Mutant("ldrequeue", "Leiden.swift", "community[w] != chosen", "false"),
    Mutant("ldwellconnected", "Leiden.swift", "guard external[v] >= gamma * (av * (totalB - bv) + bv * (totalA - av)) else { continue }", "", mode="stmt"),
    Mutant("ldrefinedwell", "Leiden.swift", "guard refinedExternal[r] >= gamma * (ra * (totalB - rb) + rb * (totalA - ra)) else { continue }", "", mode="stmt"),
    Mutant("ldnegativegain", "Leiden.swift", "guard gain >= 0 else { continue }", "", mode="stmt"),
    Mutant("ldsingleton", "Leiden.swift", "guard refined[v] == v, refinedSize[v] == 1 else { continue }", "", mode="stmt"),
    Mutant("ldexternal", "Leiden.swift", "refinedExternal[r] += external[v] - 2 * weightTo[r]", "", mode="stmt"),
    Mutant("ldsamecommunity", "Leiden.swift", "                                        guard community[w] == c else { continue }", "", mode="stmt"),
    Mutant("ldnorefine", "Leiden.swift", "count == k", "true"),
    Mutant("ldnofallback", "Leiden.swift", "                group = community.map { rank[$0] }\n                count = communities", "                break", mode="stmt"),
    Mutant("ldonelevel", "Leiden.swift", "            if communities == k { break }", "            break", mode="stmt"),
    Mutant("ldmovedflag", "Leiden.swift", "if _leidenMove(rows, &community, a: a, b: b, scale: gamma, using: &generator) { moved = true }", "_ = _leidenMove(rows, &community, a: a, b: b, scale: gamma, using: &generator)", mode="stmt"),
    Mutant("ldmovereport", "Leiden.swift", "moved = true", "", nth=0, mode="stmt"),
    Mutant("ldgammapotts", "Leiden.swift", "(directed ? resolution : resolution / 2)", "resolution"),
    Mutant("ldgammamod", "Leiden.swift", "(directed ? resolution / m : resolution / (4 * m))", "resolution / (4 * m)"),
    Mutant("ldsizes", "Leiden.swift", "modularity ? baseRows.out : [Double](repeating: 1, count: n)", "baseRows.out"),
    Mutant("ldpottsscale", "Leiden.swift", "graph.directed ? gamma : gamma / 2", "gamma / 2"),
    Mutant("ldpottsinside", "Leiden.swift", "if c == labels[graph.to[e]] { inside[c] += weights?[e] ?? 1 }", "inside[c] += weights?[e] ?? 1", mode="stmt"),
    Mutant("ldrandomness", "Leiden.swift", "randomness.isFinite && randomness > 0", "randomness.isFinite"),
    Mutant("lditerations", "Leiden.swift", "iterations.map { $0 >= 1 } ?? true", "true"),
    Mutant("lditerationlimit", "Leiden.swift", "iterations.map({ iteration < $0 }) ?? true", "true"),
    Mutant("ldpick", "Leiden.swift", "guard x >= stay else { continue }", "", mode="stmt"),

    # Hierarchical Leiden.
    Mutant("hlcap", "HierarchicalLeiden.swift", "hierarchy.offsets[c + 1] - hierarchy.offsets[c] > maximumCommunitySize", "hierarchy.offsets[c + 1] - hierarchy.offsets[c] >= maximumCommunitySize"),
    Mutant("hlnextcap", "HierarchicalLeiden.swift", "hierarchy.offsets[d + 1] - hierarchy.offsets[d] > maximumCommunitySize", "hierarchy.offsets[d + 1] - hierarchy.offsets[d] >= maximumCommunitySize"),
    Mutant("hlsplit", "HierarchicalLeiden.swift", "guard split else { continue }", "", mode="stmt"),
    Mutant("hlnext", "HierarchicalLeiden.swift", "next.append(d)", "", mode="stmt"),
    Mutant("hlparent", "HierarchicalLeiden.swift", "hierarchy.addCommunities(of: vertices, labels: labels, parent: c)", "hierarchy.addCommunities(of: vertices, labels: labels, parent: 0)"),
    Mutant("hlleaf", "HierarchicalLeiden.swift", "leaf[v] = first + canonical[i]", "", mode="stmt"),
    Mutant("hlinside", "HierarchicalLeiden.swift", "hierarchy.leaf[graph.to[e]] == hierarchy.leaf[graph.from[e]]", "true"),
    Mutant("hlweights", "HierarchicalLeiden.swift", "edges.map { weights[$0] }", "edges.map { _ in 1.0 }"),
    Mutant("hlemptylevel", "HierarchicalLeiden.swift", "guard hierarchy.parent.count > levelStart else { break }", "", mode="stmt"),
    Mutant("hlcheckcap", "HierarchicalLeiden.swift", "maximumCommunitySize >= 1", "maximumCommunitySize >= 0"),
    Mutant("hlfirstchild", "HierarchicalLeiden.swift", "if childCount[p] == 0 { firstChild[p] = c }", "firstChild[p] = c", mode="stmt"),
    Mutant("hllevel", "HierarchicalLeiden.swift", "level[c] = l", "level[c] = 0", mode="stmt"),
    Mutant("hlleaves", "HierarchicalLeiden.swift", "_childCount[c] == 0", "true"),
    Mutant("hlcanonical", "HierarchicalLeiden.swift", "renumber[label] < 0", "renumber[label] < 0 || label == 0"),
    Mutant("hllocal", "HierarchicalLeiden.swift", "local[hierarchy.members[slot]] = i", "local[hierarchy.members[slot]] = 0", mode="stmt"),
    Mutant("hlempty", "HierarchicalLeiden.swift", "guard n > 0 else { return hierarchy }", "", mode="stmt"),
    Mutant("hlparentnil", "HierarchicalLeiden.swift", "return p < 0 ? nil : p", "return p", mode="stmt"),
    Mutant("hlcheckedguard", "HierarchicalLeiden.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("hlcheckedlookup", "HierarchicalLeiden.swift", "_numbers[vertex]", "Optional(_numbers[vertex] ?? 0)", nth=1),

    # Louvain's levels and the component split.
    Mutant("lvlevels", "Louvain.swift", "levels.append(labels)", "levels = [labels]", mode="stmt"),
    Mutant("partsweight", "Leiden.swift", "labels[w] == labels[s]", "true"),

    # Kernighan–Lin.
    Mutant("klstamp", "KernighanLin.swift", "values[i] < values[j] || (values[i] == values[j] && stamps[i] < stamps[j])", "values[i] < values[j] || (values[i] == values[j] && stamps[i] > stamps[j])"),
    Mutant("klstale", "KernighanLin.swift", "current[v] == value", "true"),
    Mutant("klupdate", "KernighanLin.swift", "if value != current[v] { push(v, value) }", "push(v, value)", mode="stmt"),
    Mutant("klsign", "KernighanLin.swift", "t == side[u] ? -rows.weights[slot] : rows.weights[slot]", "rows.weights[slot]"),
    Mutant("klprefix", "KernighanLin.swift", "cost < best", "cost <= best"),
    Mutant("klstop", "KernighanLin.swift", "best >= 0", "best > 0"),
    Mutant("klswap", "KernighanLin.swift", "side[v] = 0", "", mode="stmt"),
    Mutant("klinitial", "KernighanLin.swift", "cost += side[rows.neighbors[slot]] == side[u] ? rows.weights[slot] : -rows.weights[slot]", "cost += rows.weights[slot]", mode="stmt"),
    Mutant("klmerge", "KernighanLin.swift", "weights[slotOf[w]] += x", "", mode="stmt"),
    Mutant("klsides", "KernighanLin.swift", "return labels.map { 1 - $0 }", "return labels", mode="stmt"),
    Mutant("klcount", "KernighanLin.swift", "communities.count == 2", "true"),

    # k-clique percolation.
    Mutant("kcshared", "CliquePercolation.swift", "shared[j] == k - 1", "shared[j] == k"),
    Mutant("kcsize", "CliquePercolation.swift", "cliques.filter { $0.count >= k }", "cliques.filter { $0.count > k }"),
    Mutant("kcstamp", "CliquePercolation.swift", "shared[j] = 0", "", mode="stmt"),
    Mutant("kcorder", "CliquePercolation.swift", "groups.sort { $0.lexicographicallyPrecedes($1) }", "", mode="stmt"),

    # Fluid communities.
    Mutant("flkeep", "FluidCommunities.swift", "guard !keeps else { continue }", "", mode="stmt"),
    Mutant("fltie", "FluidCommunities.swift", "most - total[c] < 1e-4", "most == total[c]"),
    Mutant("fldensity", "FluidCommunities.swift", "density[chosen] = 1 / Double(size[chosen])", "", mode="stmt"),
    Mutant("flconnected", "FluidCommunities.swift", "reached == rows.count", "true"),
    Mutant("flsweeps", "FluidCommunities.swift", "sweep < iterations", "sweep < 1"),

    # Walktrap.
    Mutant("wtloop", "Walktrap.swift", "next[u] += p * added[u]", "", mode="stmt"),
    Mutant("wtscale", "Walktrap.swift", "values.append(current[u] / degree[u].squareRoot())", "values.append(current[u])", mode="stmt"),
    Mutant("wtlance", "Walktrap.swift", "((sa + sd) * x.sigma + (sb + sd) * y.sigma - sd * ab) / (sa + sb + sd)", "x.sigma + y.sigma"),
    Mutant("wtmean", "Walktrap.swift", "vectors.append(_WalkVector.mean(vectors[a]!, sa, vectors[b]!, sb))", "vectors.append(_WalkVector.mean(vectors[a]!, 1, vectors[b]!, 1))", mode="stmt"),
    Mutant("wtbest", "Walktrap.swift", "q > bestQ", "q >= bestQ"),
    Mutant("wtinside", "Walktrap.swift", "inside.append(inside[a] + inside[b] + entry.weight)", "inside.append(inside[a] + inside[b])", mode="stmt"),
    Mutant("wtzero", "Walktrap.swift", "if count > 0, sum > 0 { added[v] = sum / Double(count) }", "if count > 0 { added[v] = sum / Double(count) }", mode="stmt"),

    # Leading eigenvector.
    Mutant("lediagonal", "LeadingEigenvector.swift", "y[i] = sum - degrees[i] * factor - diagonal[i] * x[i]", "y[i] = sum - degrees[i] * factor", mode="stmt"),
    Mutant("legain", "LeadingEigenvector.swift", "guard gain > 1e-10 * scale * Double(s) else { continue }", "", mode="stmt"),
    Mutant("leloops", "LeadingEigenvector.swift", "for v in 0 ..< rows.count { degree[v] += 2 * loops[v] }", "", mode="stmt"),
    Mutant("leempty", "LeadingEigenvector.swift", "guard m2 > 0 else { return Array(0 ..< n) }", "guard m2 > 0 else { return label }", mode="stmt"),
    Mutant("lerecurse", "LeadingEigenvector.swift", "        pending.append(first)", "", mode="stmt"),

    # Spectral clustering (k-means here, the Ng–Jordan–Weiss rows in SpectralGraphTheory).
    Mutant("njwnormalize", "SpectralEmbedding.swift", "for j in 0 ..< k { rows[v * k + j] *= inverse }", "", mode="stmt", module="SpectralGraphTheory"),
    Mutant("kmnearest", "SpectralClustering.swift",
           "                        if s < least {\n                            least = s\n                            nearest = center\n                        }",
           "                        if s < least { least = s }", mode="stmt"),
    Mutant("kmmeans", "SpectralClustering.swift", "for j in 0 ..< k { centers[center * k + j] *= inverse }", "", mode="stmt"),
    Mutant("kmbest", "SpectralClustering.swift", "inertia < bestInertia || best.isEmpty", "best.isEmpty"),
    Mutant("kmseed", "SpectralClustering.swift", "if s < distance[i] { distance[i] = s }", "", mode="stmt"),
    Mutant("kmempty", "SpectralClustering.swift", "sizes[center] == 0", "false"),
    Mutant("kmruns", "SpectralClustering.swift", "_kMeansRuns", "1", nth=1),
    Mutant("sccount", "SpectralClustering.swift", "clusterCount >= 1 && clusterCount <= vertexCount", "clusterCount >= 1"),
    Mutant("sctolerance", "SpectralClustering.swift", "precondition(tolerance > 0, \"The tolerance is not positive\")", "", mode="stmt"),
    Mutant("scweights", "SpectralClustering.swift", "_communityWeights(weight)", "nil", nth=0),

    # Leiden's final split into connected parts.
    Mutant("ldsplit", "Leiden.swift", "return _connectedParts(baseRows, membership)", "return membership", mode="stmt"),
    # Infomap and the map equation's code length.
    Mutant("implogp", "Infomap.swift", "x > 0 ? x * log2(x) : 0", "x > 0 ? x * log(x) : 0"),
    Mutant("imloopflow", "Infomap.swift", "            flow[v] += f", "            if u != v { flow[v] += f }", mode="stmt"),
    Mutant("imscale", "Infomap.swift", "1 / (2 * total)", "1 / total"),
    Mutant("imexitterm", "Infomap.swift", "return _plogp(total) - 2 * exitTerm - vertexEntropy + sizeTerm", "return _plogp(total) - exitTerm - vertexEntropy + sizeTerm", mode="stmt"),
    Mutant("imsourceexit", "Infomap.swift", "qA - ea + 2 * toSource", "qA - ea + toSource"),
    Mutant("imtargetexit", "Infomap.swift", "qB + ea - 2 * toB", "qB + ea - toB"),
    Mutant("imapplyexit", "Infomap.swift", "exit[target] = qB + ea - 2 * toTarget", "exit[target] = qB + ea", mode="stmt"),
    Mutant("imnoempty", "Infomap.swift", "size[source] > 1", "false"),
    Mutant("imshuffle", "Infomap.swift", "touched.swapAt(c, Int(generator.next(upperBound: UInt64(c + 1))))", "()", mode="stmt"),
    Mutant("imthreshold", "Infomap.swift", "guard best < -1e-10 else { continue }", "guard best < 1e-3 else { continue }", mode="stmt"),
    Mutant("imonesweep", "Infomap.swift", "        if !moved { break }", "        break", mode="stmt"),
    Mutant("imnoaggregate", "Infomap.swift", "        guard k < level.count else { break }", "        break", mode="stmt"),
    Mutant("imcompose", "Infomap.swift", "for v in labels.indices { labels[v] = module[labels[v]] }", "labels = module", mode="stmt"),
    Mutant("iminterlinks", "Infomap.swift", "                    guard j != i else { continue }", "", mode="stmt"),
    Mutant("imtune", "Infomap.swift", "tunedLength < length - 1e-10", "false"),
    Mutant("imcoarse", "Infomap.swift", "            fine.toggle()", "", mode="stmt"),
    Mutant("imsubloop", "Infomap.swift", "flow[l] = base.flow[v] - base.exit[v]", "flow[l] = 0", mode="stmt"),
    Mutant("imparent", "Infomap.swift", "for v in 0 ..< n { parent[sub[v]] = labels[v] }", "for v in 0 ..< n { parent[sub[v]] = sub[v] }", mode="stmt"),
    Mutant("imbest", "Infomap.swift", "length < bestLength - 1e-10", "length > bestLength + 1e-10"),
    Mutant("imtrials", "Infomap.swift", "0 ..< trials", "0 ..< 1"),
]
