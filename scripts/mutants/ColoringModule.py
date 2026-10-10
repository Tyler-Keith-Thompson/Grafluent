# Planted bugs for ColoringModule; run with `just mutate ColoringModule`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   sl_stale, is_stale   the stale-key skip in smallest last and the independent set: a degree only
#                        falls, and every fall pushes the new key, so a vertex's current entry is
#                        popped before any stale one, which then meets `removed` or `!available`.
#   sl_removed           a removed neighbour's degree lowered and pushed again: its entries are
#                        skipped by `removed` when popped, and its degree is never read again.
#   is_reset             clearing `available` for the uncoloured vertices after a class: every one
#                        of them was taken or dropped during the class, so it is already false. The
#                        statement is dead.
#   order_twice, order_seen, order_missing
#                        greedyColoring(order:) without its repeat or count check still traps: a
#                        vertex left out keeps colour −1, which indexes out of range in Coloring's
#                        init (a worse message, the same trap).
#   order_foreign, coloring_contains
#                        without the contains check, vertexIndex(of:) on a non-vertex traps in each
#                        representation, or the index falls outside the colour vector.
#   coloring_index       without `index >= 0`, the colour vector's subscript traps on a negative
#                        index.
#   ends_loop            Misra–Gries without the self-loop check: a self-loop is in its vertex's row
#                        twice, so the parallel-edge check traps on its second appearance.
#   mg_prefix            the "F up to w is still a fan" break: by Misra and Gries's lemma some fan
#                        vertex with d free has an intact prefix, so the first vertex with d free is
#                        reached before any broken link, and the break never fires.
#   exact_partchi        `chi = max(chi, 2)` for a bipartite component: the whole graph is not
#                        bipartite there, so another component lifts χ to at least 3, and every
#                        skip test it feeds compares with DSatur bounds of at least 3.
#   exact_noskip, exact_three, bb_interchange, lex_fastpath, lex_initial
#                        pruning and shortcuts: never skipping a component, a lower bound of the
#                        clique alone (2 just fails one more decision), trying every colour instead
#                        of one new one, no first-fit shortcut, the witness not renumbered first.
#                        Each decides the same questions, only more slowly (bb_interchange triples
#                        the suite's time).
#   bb_preset, lex_clash the preset check in extend and the clash check in the lexicographic pass
#                        guard the same thing (a preset colour that a neighbour already has, or one
#                        out of range, which the callers never pass); each one alone suffices.
#
# Order matters where patterns overlap: lf_degree edits the counting loop before lf_tie replaces
# the filling loop; check_holder drops the holder test before check_loopedge edits its condition;
# rows_repeat and rows_loop both edit one statement.

TESTS = ["ColoringModuleTests"]

MUTANTS = [
    # Simple rows
    Mutant("rows_repeat", "ColoringRows.swift", "                if w == v || stamp[w] == v { continue }", "                if w == v { continue }", mode="stmt"),
    Mutant("rows_loop", "ColoringRows.swift", "                if w == v || stamp[w] == v { continue }", "                if stamp[w] == v { continue }", mode="stmt"),

    # The heap shared by smallest last, DSatur and the independent set
    Mutant("heap_tie", "ColoringRows.swift", "ka < kb || (ka == kb && ia < ib)", "ka < kb || (ka == kb && ia > ib)"),
    Mutant("heap_child", "ColoringRows.swift", "_less(keys[l + 1], items[l + 1], keys[l], items[l])", "false"),

    # First fit
    Mutant("firstfit_mark", "GreedyColoring.swift", "            if c >= 0 { used[c] = v }", "", mode="stmt"),
    Mutant("firstfit_skip", "GreedyColoring.swift", "        while used[c] == v { c += 1 }", "        while used[c] == v || c == 1 { c += 1 }", mode="stmt"),

    # Largest first
    Mutant("lf_degree", "GreedyColoring.swift", "top - rows.degree(v) + 1", "rows.degree(v) + 1"),
    Mutant("lf_tie", "GreedyColoring.swift",
           "    for v in 0 ..< n {\n        let slot = top - rows.degree(v)\n        order[starts[slot]] = v\n        starts[slot] += 1\n    }",
           "    for v in (0 ..< n).reversed() {\n        let slot = top - rows.degree(v)\n        order[starts[slot]] = v\n        starts[slot] += 1\n    }",
           mode="stmt"),

    # Smallest last
    Mutant("sl_stale", "GreedyColoring.swift", "key != UInt64(degree[v])", "false", nth=0),
    Mutant("sl_removed", "GreedyColoring.swift", "            if removed[w] { continue }", "", mode="stmt"),
    Mutant("sl_decrement", "GreedyColoring.swift", "            degree[w] -= 1", "", mode="stmt"),
    Mutant("sl_reverse", "GreedyColoring.swift", "        order[slot] = v", "        order[n - 1 - slot] = v", mode="stmt"),

    # DSatur
    Mutant("ds_fresh", "GreedyColoring.swift", "                fresh = seen[i] & bit == 0", "                fresh = true", mode="stmt"),
    Mutant("ds_highfresh", "GreedyColoring.swift", "                fresh = high.insert(w &* bound &+ c).inserted", "                fresh = true", mode="stmt"),
    Mutant("ds_bitset", "GreedyColoring.swift", "c <= dw", "false"),
    Mutant("ds_word", "GreedyColoring.swift", "            c += 64", "            c += 63", mode="stmt"),

    # Independent set
    Mutant("is_initial", "GreedyColoring.swift", "available[rows.neighbors[k]]", "true"),
    Mutant("is_stale", "GreedyColoring.swift", "key != UInt64(degree[v])", "false", nth=1),
    Mutant("is_drop", "GreedyColoring.swift", "                    available[w] = false", "", mode="stmt"),
    Mutant("is_degree", "GreedyColoring.swift", "                        degree[y] -= 1", "", mode="stmt"),
    Mutant("is_reset", "GreedyColoring.swift", "            available[v] = false\n            kept += 1", "            kept += 1", mode="stmt"),

    # Connected sequential
    Mutant("cs_swap", "GreedyColoring.swift", "depthFirst", "!depthFirst", nth=1),
    Mutant("cs_bfsroot", "GreedyColoring.swift", "order.count - 1", "order.count", nth=0),
    Mutant("cs_bfsseen", "GreedyColoring.swift", "                    seen[rows.neighbors[k]] = true", "", mode="stmt"),
    Mutant("cs_dfsdescend", "GreedyColoring.swift", "                stack.append(w)\n                cursor.append(rows.offsets[w])", "", mode="stmt"),

    # greedyColoring(order:)
    Mutant("order_twice", "GreedyColoring.swift", r'            precondition(!seen[v], "\(vertex) appears twice in the order")', "", mode="stmt"),
    Mutant("order_seen", "GreedyColoring.swift", "            seen[v] = true", "", mode="stmt"),
    Mutant("order_missing", "GreedyColoring.swift", r'        precondition(sequence.count == n, "The order misses \(n - sequence.count) vertices")', "", mode="stmt"),
    Mutant("order_foreign", "GreedyColoring.swift", r'                precondition(contains(vertex), "\(vertex) in the order is not a vertex of the graph")', "", mode="stmt"),

    # Coloring
    Mutant("coloring_classes", "Coloring.swift", "            fill[colors[v]] += 1", "", mode="stmt"),
    Mutant("coloring_equal", "Coloring.swift", "lhs._colors == rhs._colors", "lhs._offsets == rhs._offsets"),
    Mutant("coloring_colorof", "Coloring.swift", "            return _colors[v]", "            return _colors[_colors.count - 1 - v]", mode="stmt"),
    Mutant("coloring_contains", "Coloring.swift", r'        precondition(_graph.contains(vertex), "\(vertex) is not a vertex of the graph")', "", mode="stmt"),
    Mutant("coloring_index", "Coloring.swift", "index >= 0 && index < _colors.count", "index < _colors.count"),

    # EdgeColoring
    Mutant("ec_classes", "EdgeColoring.swift", "            fill[colors[e]] += 1", "", mode="stmt"),
    Mutant("ec_equal", "EdgeColoring.swift", "lhs._colors == rhs._colors", "lhs._offsets == rhs._offsets"),
    Mutant("ec_search", "EdgeColoring.swift", "_positions[mid] < position", "_positions[mid] <= position"),
    Mutant("flip_alternate", "EdgeColoring.swift", "            c = c == c1 ? c2 : c1", "            c = c1", mode="stmt"),
    Mutant("flip_recolor", "EdgeColoring.swift", "            next = next == c1 ? c2 : c1", "            next = c2", mode="stmt"),
    Mutant("ends_loop", "EdgeColoring.swift", '                precondition(w != v, "edgeColoring() requires a simple graph: the graph has a self-loop")', "", mode="stmt"),
    Mutant("ends_parallel", "EdgeColoring.swift", "                stamp[w] = v", "", mode="stmt"),

    # Misra–Gries
    Mutant("mg_fanrepeat", "EdgeColoring.swift", "inFan[x] != e", "true"),
    Mutant("mg_fanfree", "EdgeColoring.swift", "                    guard f >= 0, table.isFree(last, k) else { continue }", "                    guard f >= 0 else { continue }", mode="stmt"),
    Mutant("mg_fanmark", "EdgeColoring.swift", "                inFan[x] = e", "", mode="stmt"),
    Mutant("mg_cfree", "EdgeColoring.swift", "table.isFree(fan[fan.count - 1], c)", "false", nth=1),
    Mutant("mg_flip", "EdgeColoring.swift", "                table.flip(from: u, d, c)", "", mode="stmt"),
    Mutant("mg_prefix", "EdgeColoring.swift", "                if i > 0, !table.isFree(fan[i - 1], table.color[fanEdges[i]]) { break }", "", mode="stmt"),
    Mutant("mg_shift", "EdgeColoring.swift", "            for j in 0 ..< w { shifted.append(table.color[fanEdges[j + 1]]) }", "            for j in 0 ..< w { shifted.append(table.color[fanEdges[j]]) }", mode="stmt"),
    Mutant("mg_last", "EdgeColoring.swift", "            table.set(fanEdges[w], d)", "            table.set(fanEdges[w], c)", mode="stmt"),

    # König
    Mutant("konig_bipartite", "EdgeColoring.swift", "        guard _TwoColoring(witness: false).run(count: n, edgeCount: m, &rows).sides != nil else { return nil }", "", mode="stmt"),
    Mutant("konig_flip", "EdgeColoring.swift", "            if !table.isFree(v, a) { table.flip(from: v, a, b) }", "", mode="stmt"),
    Mutant("konig_color", "EdgeColoring.swift", "            table.set(e, a)", "            table.set(e, b)", mode="stmt"),

    # Checks
    Mutant("check_loop", "ColoringChecks.swift", "w != v && colors[w] == c", "colors[w] == c"),
    Mutant("check_holder", "ColoringChecks.swift", "                    if holder[c] != e { return false }", "", mode="stmt"),
    Mutant("check_loopedge", "ColoringChecks.swift", "holder[c] != e", "true"),
    Mutant("check_dense", "ColoringChecks.swift", "low < 0 || high >= 2 * m + 1", "high >= 2 * m + 1"),

    # Exact search: components, whole-graph cases, per-component handling and skipping
    Mutant("exact_edgeless", "ExactColoring.swift", "    guard !rows.neighbors.isEmpty else { return (1, colors) }", "", mode="stmt"),
    Mutant("exact_wholesides", "ExactColoring.swift", "Int(sides[v])", "1 - Int(sides[v])"),
    Mutant("exact_partsides", "ExactColoring.swift", "Int(sides[i])", "1 - Int(sides[i])"),
    Mutant("exact_partchi", "ExactColoring.swift", "            chi = max(chi, 2)", "", mode="stmt"),
    Mutant("exact_components", "ExactColoring.swift", "                component[rows.neighbors[k]] = count", "", mode="stmt"),
    Mutant("exact_skip", "ExactColoring.swift", "upper > floor", "upper > floor + 1"),
    Mutant("exact_noskip", "ExactColoring.swift", "lexicographic ? 0 : chi", "0"),

    # Exact search: bounds and clique seeding
    Mutant("exact_lower", "ExactColoring.swift", "lower ..< upper", "lower + 1 ..< upper"),
    Mutant("exact_three", "ExactColoring.swift", "max(3, clique.count)", "clique.count"),
    Mutant("exact_seed", "ExactColoring.swift", "        for (i, v) in clique.enumerated() { preset[v] = i }", "        for v in clique { preset[v] = 0 }", mode="stmt"),
    Mutant("clique_adjacent", "ExactColoring.swift", "hits[x] == clique.count", "true"),
    Mutant("clique_undo", "ExactColoring.swift", "                for k in rows.offsets[y] ..< rows.offsets[y + 1] { hits[rows.neighbors[k]] -= 1 }", "", mode="stmt"),

    # Exact search: DSatur branch and bound
    Mutant("bb_count", "ExactColoring.swift", "            counts[slot] += 1", "", mode="stmt"),
    Mutant("bb_unmask", "ExactColoring.swift", "                masks[w &* words &+ word] &= ~bit", "", mode="stmt"),
    Mutant("bb_newcolor", "ExactColoring.swift", "min(colors - 1, base + 1)", "min(colors - 1, base)"),
    Mutant("bb_interchange", "ExactColoring.swift", "min(colors - 1, base + 1)", "colors - 1"),
    Mutant("bb_deadend", "ExactColoring.swift", "bestSaturation >= colors", "false"),
    Mutant("bb_preset", "ExactColoring.swift", "            guard c < colors, allows(v, c) else { return false }", "", mode="stmt"),

    # Exact search: the lexicographic pass
    Mutant("lex_fastpath", "ExactColoring.swift", "        if !fit.contains(where: { $0 >= chi }) { return fit }", "", mode="stmt"),
    Mutant("lex_clash", "ExactColoring.swift", "                    clash = true", "", mode="stmt"),
    Mutant("lex_witness", "ExactColoring.swift", "                    witness = color", "", mode="stmt"),
    Mutant("lex_chosen", "ExactColoring.swift", "                    chosen = c", "", mode="stmt"),
    Mutant("lex_high", "ExactColoring.swift", "            high = max(high, chosen)", "", mode="stmt"),
    Mutant("lex_initial", "ExactColoring.swift", "        _restrictGrowth(&witness, from: 0, high: -1, scratch: &scratch)", "", mode="stmt"),
    Mutant("lex_keep", "ExactColoring.swift", "        if c <= high { continue }", "", mode="stmt"),
]
