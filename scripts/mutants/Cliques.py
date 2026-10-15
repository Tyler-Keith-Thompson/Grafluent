# Planted bugs for Cliques; run with `just mutate Cliques`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   laterrows, forward  ranks are unique, so >= and > pick the same vertices.
#   bbmc_bound          `<` for `<=` in the colour bound prunes less: the same optimum, slower.
#   pivotscore          the first pivot loop's ties by order met rather than by index: no graph
#                       among 3000 differential cases tells them apart (the X ∩ P members it
#                       passes over were branched on in the same frame). pivotscorex, the tie
#                       rule against X₀, is caught by CQ-1006.

#   chordal witness     which violation `hole()` starts from, and the search over every vertex
#                       and pair after the failed test's own pair: in 20 000 random graphs and
#                       every test, that first pair always has a path, so the fallback is never
#                       reached and its mutants would survive unseen; they are left out.

#   removed as equivalent:
#   tr_loopsimple       keeping a self-loop in the truss rows: its slot is never forward (equal
#                       rank), and in the peel the loop's far end is the edge's own end, whose other
#                       edge is the one being removed, so it is skipped.
#   tr_forward          `>=` for `>` in the forward rows: ranks are unique.
#   on_stale            dropping the degree test when popping stale bucket entries: when no vertex
#                       is left at the core, every vertex that dropped to it is already layered,
#                       so a live entry's degree is its bucket's; the collecting filter checks again.
#   mw_target           `>=` for `>` when the cover stops: more candidates are branched on, the
#                       same optimum.
#   mw_leave            keeping a branched candidate among its siblings' candidates: cliques are
#                       found again through them, the same optimum, slower.
#   mw_skip             `>=` for `>` when skipping a vertex whose candidates' total cannot beat the
#                       best: a tie is never taken, so the search finds nothing.

#   td_fill_zero        no early stop at fill-in zero: nothing later is below zero; time only.
#   td_valid_loop       allowing a bag edge to itself: with B − 1 edges one of them wasted leaves the
#                       bags disconnected, which the reach check rejects.
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

    # Chordal graphs
    Mutant("ch_follower", "Chordal.swift", "position[u] > position[follower[v]]", "position[u] < position[follower[v]]"),
    Mutant("ch_requirement", "Chordal.swift", "stamp[required[i]] != f", "stamp[required[i]] == f"),
    Mutant("ch_avoid", "Chordal.swift", "        banned[v] = true", "", mode="stmt"),
    Mutant("ch_dominated", "Chordal.swift", "earlierCount[w] == earlierCount[follower[w]] + 1", "false"),
    Mutant("ch_sort", "Chordal.swift", "            clique.sort()", "", mode="stmt"),
    Mutant("ch_orient", "Chordal.swift", "edges[edges.count - 1] < edges[0]", "false"),
    Mutant("ch_treewidth", "Chordal.swift", "largest - 1", "largest"),

    # Truss decomposition
    Mutant("tr_support", "Trusses.swift", "                support[markEdge[forward[j]]] += 1", "", mode="stmt"),
    Mutant("tr_plustwo", "Trusses.swift", "s + 2", "s + 3"),
    Mutant("tr_removed", "Trusses.swift", "!removed[aw]", "true"),
    Mutant("tr_removedother", "Trusses.swift", "            guard !removed[bw] else { continue }", "", mode="stmt"),
    Mutant("tr_decrement", "Trusses.swift", "support[f] > s", "support[f] >= s && support[f] > 0"),
    Mutant("tr_bin", "Trusses.swift", "                bin[sf] += 1", "", mode="stmt"),
    Mutant("tr_least", "Trusses.swift", "max(k, 2)", "k"),
    Mutant("tr_loopnil", "Trusses.swift", "_truss[e] == 0", "false", nth=0),
    Mutant("tr_identity", "Trusses.swift", "e >= 0 && e < _truss.count", "true"),

    # Onion layers, crusts, coronas
    Mutant("on_isolated", "OnionLayers.swift", "    if remaining < n { number = 2 }", "    number = 2", mode="stmt"),
    Mutant("on_raise", "OnionLayers.swift", "            core = pointer", "", mode="stmt"),
    Mutant("on_next", "OnionLayers.swift", "degree[w] == core", "degree[w] == core - 1"),
    Mutant("on_layer", "OnionLayers.swift", "        number += 1", "", mode="stmt"),
    Mutant("on_checked", "OnionLayers.swift", "        guard _graph.contains(vertex) else { throw VertexNotFound() }", "        guard true else { throw VertexNotFound() }", mode="stmt"),
    Mutant("crust", "CoreNumbers.swift", "_core[$0] <= k", "_core[$0] < k"),
    Mutant("corona", "CoreNumbers.swift", "_core[rows.targets[slot]] >= k", "_core[rows.targets[slot]] > k"),
    Mutant("coronaexact", "CoreNumbers.swift", "inCore == k", "inCore >= k"),

    # Every clique
    Mutant("ac_minprune", "AllCliques.swift", "size + reach >= minimum", "size + reach > minimum"),
    Mutant("ac_max", "AllCliques.swift", "size < maximum", "true"),
    Mutant("ac_child", "AllCliques.swift", "frames[base + k] & rows[w * words + k]", "rows[w * words + k]", nth=1),
    Mutant("ac_single", "AllCliques.swift", "minimum <= 1", "minimum <= 0"),
    Mutant("ac_rootprune", "AllCliques.swift", "1 + p >= minimum", "p >= minimum"),
    Mutant("ac_leaf", "AllCliques.swift", "                leaf = true", "", mode="stmt"),
    Mutant("ac_sort", "AllCliques.swift", "                found.sort()", "", mode="stmt"),
    Mutant("ac_bounds", "AllCliques.swift", "range.upperBound - 1", "range.upperBound"),

    # Maximal cliques through a vertex
    Mutant("mc_lonely", "MaximalCliques.swift", "                    lonely = members.isEmpty", "                    lonely = false", mode="stmt"),
    Mutant("mc_add", "MaximalCliques.swift", "            clique.append(containing)", "", mode="stmt"),
    Mutant("mc_sort", "MaximalCliques.swift", "            clique.sort()", "", mode="stmt"),
    Mutant("mc_checked", "MaximalCliques.swift", "        guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),

    # Maximum-weight clique and the clique number of a vertex
    Mutant("tr_transpose", "Trusses.swift", "                fill[w] += 1", "", mode="stmt"),
    Mutant("mw_residual", "MaximumWeightClique.swift", "                residual[i] -= least", "", mode="stmt"),
    Mutant("mw_drop", "MaximumWeightClique.swift", "                if residual[i] == .zero { work[i >> 6] &= ~(1 << UInt64(i & 63)) }", "", mode="stmt"),
    Mutant("mw_independent", "MaximumWeightClique.swift", "                    for j in k ..< words { open[j] &= ~rows[i * words + j] }", "", mode="stmt"),
    Mutant("mw_child", "MaximumWeightClique.swift", "                for j in 0 ..< words { sets[base + words + j] = sets[base + j] & rows[i * words + j] }", "                for j in 0 ..< words { sets[base + words + j] = sets[base + j] }", mode="stmt"),
    Mutant("mw_positive", "MaximumWeightClique.swift", "weights[v] > .zero", "true"),
    Mutant("mw_backrow", "MaximumWeightClique.swift", "                    search.rows[j * words + i >> 6] |= 1 << UInt64(i & 63)", "", mode="stmt"),
    Mutant("cn_vertex", "MaximumWeightClique.swift", "_cliqueNumber(neighborhood.rows).clique.count + 1", "_cliqueNumber(neighborhood.rows).clique.count"),
    Mutant("cn_checked", "MaximumWeightClique.swift", "        guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    # Tree decompositions
    Mutant("td_width", "TreeDecomposition.swift", "(bags.lazy.map(\\.count).max() ?? 0) - 1", "(bags.lazy.map(\\.count).max() ?? 0)"),
    Mutant("td_clique_stop_degree", "TreeDecomposition.swift", "adjacency[u].count != remaining - 1", "adjacency[u].count != remaining"),
    Mutant("td_clique_stop_fill", "TreeDecomposition.swift", "if adjacency[byDegree[0]].count == remaining - 1 { break }", "", mode="stmt"),
    Mutant("td_priority", "TreeDecomposition.swift", "rows.degree(v) &* n &+ v", "rows.degree(v) &* n &- v"),
    Mutant("td_update", "TreeDecomposition.swift", "if !minimumFillIn { queue.updatePriority(of: u, to: adjacency[u].count &* n &+ u) }", "", mode="stmt"),
    Mutant("td_fill_clique", "TreeDecomposition.swift", "for w in around where w != u && stamp[w] != round { adjacency[u].append(w) }", "", mode="stmt"),
    Mutant("td_drop_v", "TreeDecomposition.swift", "adjacency[u].removeLast()", "()", mode="stmt"),
    Mutant("td_fill_count", "TreeDecomposition.swift", "missing += around.count - 1 - shared", "missing += around.count - shared"),
    Mutant("td_fill_better", "TreeDecomposition.swift", "missing < best", "missing <= best"),
    Mutant("td_fill_early", "TreeDecomposition.swift", "if best != Int.max && missing >= best { break }", "if best != Int.max && missing >= best / 2 { break }", mode="stmt"),
    Mutant("td_bucket", "TreeDecomposition.swift", "bucketStart[adjacency[u].count + 1] += 1", "bucketStart[adjacency[u].count] += 1", mode="stmt"),
    Mutant("td_parent_first", "TreeDecomposition.swift", "step[u] < step[next]", "step[u] > step[next]"),
    Mutant("td_parent_root", "TreeDecomposition.swift", "parents.append(next < 0 ? 0 : step[next] + 1)", "parents.append(next < 0 ? 0 : step[next])", mode="stmt"),
    Mutant("td_bag_v", "TreeDecomposition.swift", "bags.append(([v] + around).sorted())", "bags.append(around.sorted())", mode="stmt"),
    Mutant("td_root_bag", "TreeDecomposition.swift", "(0 ..< n).filter { alive[$0] }", "[Int]()"),
    Mutant("td_valid_count", "TreeDecomposition.swift", "decomposition.edges.count == bagCount - 1", "true"),
    Mutant("td_valid_reach", "TreeDecomposition.swift", "guard reached == bagCount else { return false }", "", mode="stmt"),
    Mutant("td_valid_foreign", "TreeDecomposition.swift", "guard contains(vertex) else { return false }", "", mode="stmt"),
    Mutant("td_valid_connected", "TreeDecomposition.swift", "guard count == bags.count else { return false }", "", mode="stmt"),
    Mutant("td_valid_edges", "TreeDecomposition.swift", "guard shared else { return false }", "", mode="stmt"),
    Mutant("td_valid_dup", "TreeDecomposition.swift", "if holding[v].last != b { holding[v].append(b) }", "holding[v].append(b)", mode="stmt"),
    # Bron–Kerbosch as an event sequence
    Mutant("bk_enter", "MaximalCliques.swift", "observer.enter(self, at: child)", "", mode="stmt"),
    Mutant("bk_leave", "MaximalCliques.swift", "observer.leave()", "", mode="stmt", nth=2),
    Mutant("bk_pivot", "MaximalCliques.swift", "observer.pivot(self, choosePivot(at: child))", "choosePivot(at: child)", mode="stmt"),
    Mutant("bk_alone", "MaximalCliques.swift", "observer.enterAlone(self, v)", "", mode="stmt"),
    Mutant("bkr_x0", "BronKerboschEvents.swift", "excluded.append(search.xVertices[k << 6 | x.trailingZeroBitCount])", "", mode="stmt"),
    Mutant("bkr_xp", "BronKerboschEvents.swift", "excluded.append(search.pVertices[k << 6 | x.trailingZeroBitCount])", "", mode="stmt"),
    Mutant("bkr_p", "BronKerboschEvents.swift", "candidates.append(search.pVertices[k << 6 | p.trailingZeroBitCount])", "", mode="stmt"),
    Mutant("bkr_xsort", "BronKerboschEvents.swift", "excluded.sort()", "", mode="stmt"),
    Mutant("bkr_rsort", "BronKerboschEvents.swift", "clique.sort()", "", mode="stmt"),
    Mutant("bkr_rrest", "BronKerboschEvents.swift", "for k in search.clique.indices.dropFirst() { clique.append(search.pVertices[search.clique[k]]) }", "", mode="stmt"),
    Mutant("bkr_alonex", "BronKerboschEvents.swift", "search.xVertices.sorted().map(_vertex)", "search.xVertices.map(_vertex)"),
    Mutant("bkr_added", "BronKerboschEvents.swift", "search.clique.count == 1 ? search.clique[0] : search.pVertices[search.clique[search.clique.count - 1]]", "search.clique[0]"),
    Mutant("bkr_pivotx", "BronKerboschEvents.swift", "member < p ? search.pVertices[member] : search.xVertices[member - p]", "search.pVertices[min(member, p - 1)]"),
]
