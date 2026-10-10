# Planted bugs for Covering; run with `just mutate Covering`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   bbmc_bound            `<` for `<=` in the colour bound prunes less: the same optimum, slower.
#   dominating_noallowed, dominating_bound
#                         pruning removed from the dominating search: it still exhausts the same
#                         tree within the budget and finds the same least set.
#   dominating_budget     the budget check: the coverage bound already prunes a node with no budget
#                         left and something undominated (most · 0 < undominated).
#   sparse_forced, sparse_infeasible, sparse_sum, sparse_packing
#                         the sparse dominating search's forced-dominator rule, its infeasibility
#                         flag and its two lower bounds: without any one, branching still reaches
#                         the same least set (a vertex left with no allowed dominator fails the
#                         node through the others), only more slowly. Graphs of mean degree up to
#                         about √n take this search, so the catalog's sparse rows and the property
#                         tests do run it.
#   konig_matched         following the matched edge from a reached left vertex: it is reached
#                         from its mate (or is a free root), so the mate is already reached.

TESTS = ["CoveringTests"]

MUTANTS = [
    # Simple rows
    Mutant("loopflag", "CoveringGraph.swift", "                    hasLoop[v] = true", "", mode="stmt"),
    Mutant("repeats", "CoveringGraph.swift", "if stamp[w] == v { continue }", "", mode="stmt"),

    # Exact searches
    Mutant("components_conflict", "ExactCovering.swift", "color[w] == color[v]", "false"),
    Mutant("lattice_choice", "ExactCovering.swift", "if choice[x] == 1 { inSet[x] = true } else { inSet[mate[x]] = true }", "if choice[x] == 2 { inSet[x] = true } else { inSet[mate[x]] = true }", mode="stmt"),
    Mutant("lattice_forward", "ExactCovering.swift", "                        choice[b] = 1", "", mode="stmt"),
    Mutant("lattice_backward", "ExactCovering.swift", "                        choice[a] = 2", "", mode="stmt"),
    Mutant("bbmc_bound", "ExactCovering.swift", "depth + colors[i] <= bestSize", "depth + colors[i] < bestSize"),
    Mutant("dominating_noallowed", "ExactCovering.swift", "if count == 0 { return -1 }", "", mode="stmt"),
    Mutant("dominating_bound", "ExactCovering.swift", "if most * remaining < undominated { return -1 }", "", mode="stmt"),
    Mutant("dominating_budget", "ExactCovering.swift", "if remaining <= 0 { return -1 }", "", mode="stmt"),

    # Kernel reductions and the sparse dominating search
    Mutant("kernel_triangle", "ExactCovering.swift", "adjacent(a, b)", "false", nth=0),
    Mutant("kernel_leaf", "ExactCovering.swift", "                if a >= 0 { delete(a) }", "", mode="stmt"),
    Mutant("sparse_forced", "ExactCovering.swift", "                    forced.append(x)", "", mode="stmt", nth=0),
    Mutant("sparse_infeasible", "ExactCovering.swift", "                    infeasible = true", "", mode="stmt", nth=0),
    Mutant("sparse_sum", "ExactCovering.swift", "if sum < open { return -1 }", "", mode="stmt"),
    Mutant("sparse_packing", "ExactCovering.swift", "if packing(limit: left) > left { return -1 }", "", mode="stmt"),

    # Bar-Yehuda–Even
    Mutant("bye_subtract", "Approximations.swift", "                cost[b] -= cost[a]", "", mode="stmt"),
    Mutant("bye_tie", "Approximations.swift", "cost[a] <= cost[b]", "cost[a] < cost[b]"),

    # Greedy dominating set
    Mutant("greedy_index", "Approximations.swift", "            return x.v < y.v", "            return x.v > y.v", mode="stmt"),
    Mutant("greedy_stale", "Approximations.swift", "k != top.k", "false"),
    Mutant("greedy_selfcount", "Approximations.swift", "                undominated[x] -= 1", "", mode="stmt"),
    Mutant("greedy_integer", "Approximations.swift", "a * W(kb) < b * W(ka)", "a / W(ka) < b / W(kb)"),

    # Maximal independent set
    Mutant("mis_seedloop", "MaximalAndKonig.swift", "looped || blocked[v]", "blocked[v]"),
    Mutant("mis_loop", "MaximalAndKonig.swift", "if looped { continue }", "", mode="stmt"),

    # König
    Mutant("konig_matched", "MaximalAndKonig.swift", "mate[v] != u", "true"),
    Mutant("konig_back", "MaximalAndKonig.swift", "mate[v] >= 0", "false"),
    Mutant("konig_sides", "MaximalAndKonig.swift", "cover[v] = isLeft[v] != reached[v]", "cover[v] = isLeft[v] == reached[v]", mode="stmt"),

    # Edge cover
    Mutant("ec_isolated", "MaximalAndKonig.swift", "guard structure.offsets[v] < structure.offsets[v + 1] else { return nil }", "", mode="stmt"),
    Mutant("ec_covers", "MaximalAndKonig.swift", "covered[structure.to[e]] = true", "", nth=0, mode="stmt"),

    # Checks
    Mutant("vc_loop", "MaximalAndKonig.swift", "if graph.hasLoop[v] { return false }", "", nth=0, mode="stmt"),
    Mutant("ds_neighbors", "MaximalAndKonig.swift", "for k in graph.offsets[v] ..< graph.offsets[v + 1] { dominated[graph.neighbors[k]] = true }", "", mode="stmt"),
]
