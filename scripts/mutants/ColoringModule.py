# Planted bugs for ColoringModule; run with `just mutate ColoringModule`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   order_twice, order_seen, order_missing, order_foreign, coloring_contains
#                        greedyColoring(order:) without its repeat or count check still traps: a
#                        vertex left out keeps colour −1, which indexes out of range in Coloring's
#                        init (a worse message, the same trap); without the check of the vertex
#                        at that index, vertexIndex(of:) on a non-vertex traps in each
#                        representation, or the index falls outside the colour vector.
#   coloring_index       without `index >= 0`, the colour vector's subscript traps on a negative
#                        index.
#   ends_loop            Misra–Gries without the self-loop check: a self-loop is in its vertex's row
#                        twice, so the parallel-edge check traps on its second appearance.
#   exact_noskip, exact_three, bb_interchange, lex_fastpath, lex_initial
#                        pruning and shortcuts: never skipping a component, a lower bound of the
#                        clique alone (2 just fails one more decision), trying every colour instead
#                        of one new one, no first-fit shortcut, the witness not renumbered first.
#                        Each decides the same questions, only more slowly (bb_interchange triples
#                        the suite's time); without the skip, minimumColoring() may return another
#                        optimal colouring, which its tests accept.
#   bb_deadend           without the dead-end test, the vertex with no colour left is opened as a
#                        frame instead, every colour of which fails at once with the same
#                        explanation (its neighbours' frames), so the search backs up the same way.
#
# Order matters where patterns overlap: lf_degree edits the counting loop before lf_tie replaces
# the filling loop; check_holder drops the holder test before check_loopedge edits its condition;
# rows_repeat and rows_loop both edit one statement; firstfit_skip's text is also inside
# ffrows_skip's, hence its nth; sl_lower wraps the statement that sl_removed
# then edits; kempe_chosen and region_chosen are the two `chosen = c`, and mg_fanfree and
# mg_fanrepeat each have a second form for vertices with tables.

TESTS = ["ColoringModuleTests"]

MUTANTS = [
    # Simple rows
    Mutant("rows_repeat", "ColoringRows.swift", "                if w == v || stamp[w] == v { continue }", "                if w == v { continue }", mode="stmt"),
    Mutant("rows_loop", "ColoringRows.swift", "                if w == v || stamp[w] == v { continue }", "                if stamp[w] == v { continue }", mode="stmt"),

    # The indexed heap shared by smallest last, DSatur and the independent set
    Mutant("heap_tie", "ColoringRows.swift", "ka < kb || (ka == kb && a < b)", "ka < kb || (ka == kb && a > b)"),
    Mutant("heap_child", "ColoringRows.swift", "_less(heap[l + 1], heap[l])", "false"),
    Mutant("heap_up", "ColoringRows.swift", "            guard _less(item, above) else { break }", "            break", mode="stmt"),
    Mutant("heap_lower", "ColoringRows.swift", "        _up(item, from: position[item])", "        key[item] = key[item]", mode="stmt"),
    Mutant("heap_popped", "ColoringRows.swift", "        position[top] = -1", "", mode="stmt"),

    # igraph's two-way heap (colored neighbours)
    Mutant("twoway_up", "ColoringRows.swift", "data[elem] < data[parent]", "data[elem] <= data[parent]"),
    Mutant("twoway_sink", "ColoringRows.swift", "data[left] >= data[right]", "data[left] > data[right]"),
    Mutant("twoway_modify", "ColoringRows.swift", "        _shiftUp(position)", "", mode="stmt"),
    Mutant("twoway_popped", "ColoringRows.swift", "        place[top] = 0", "", mode="stmt"),

    # First fit
    Mutant("firstfit_mark", "GreedyColoring.swift", "            if c >= 0 && c < used.count { used[c] = v }", "", mode="stmt"),
    Mutant("firstfit_bound", "GreedyColoring.swift", "c >= 0 && c < used.count", "c >= 0", nth=0),
    Mutant("firstfit_skip", "GreedyColoring.swift", "        while used[c] == v { c += 1 }", "        while used[c] == v || c == 1 { c += 1 }", mode="stmt", nth=0),
    Mutant("firstfit_preset", "GreedyColoring.swift", "colors[v] < 0", "true", nth=0),

    # Largest first
    Mutant("lf_degree", "GreedyColoring.swift", "top - rows.degree(v) + 1", "rows.degree(v) + 1"),
    Mutant("lf_tie", "GreedyColoring.swift",
           "    for v in 0 ..< n {\n        let slot = top - rows.degree(v)\n        order[starts[slot]] = v\n        starts[slot] += 1\n    }",
           "    for v in (0 ..< n).reversed() {\n        let slot = top - rows.degree(v)\n        order[starts[slot]] = v\n        starts[slot] += 1\n    }",
           mode="stmt"),

    # Smallest last
    Mutant("sl_lower", "GreedyColoring.swift", "            if heap.contains(w) { heap.lower(w, heap.key[w] - 1) }", "", mode="stmt"),
    Mutant("sl_removed", "GreedyColoring.swift", "heap.contains(w)", "true", nth=0),
    Mutant("sl_reverse", "GreedyColoring.swift", "        order[slot] = v", "        order[n - 1 - slot] = v", mode="stmt"),

    # DSatur
    Mutant("ds_fresh", "GreedyColoring.swift", "                fresh = seen[i] & bit == 0", "                fresh = true", mode="stmt"),
    Mutant("ds_highfresh", "GreedyColoring.swift", "                fresh = high.insert(_VertexColor(vertex: w, color: c)).inserted", "                fresh = true", mode="stmt"),
    Mutant("ds_bitset", "GreedyColoring.swift", "c <= dw", "false"),
    Mutant("ds_word", "GreedyColoring.swift", "                free += 64", "                free += 63", mode="stmt"),
    Mutant("ds_presets", "GreedyColoring.swift", "    if preset != nil { for v in 0 ..< n where colors[v] >= 0 { pending.append(v) } }", "", mode="stmt"),
    Mutant("ds_presetcolor", "GreedyColoring.swift", "            c = colors[v]", "            c = 0", mode="stmt"),

    # Independent set
    Mutant("is_initial", "GreedyColoring.swift", "available[adjacency[k]]", "true"),
    Mutant("is_drop", "GreedyColoring.swift", "                    available[w] = false", "", mode="stmt"),
    Mutant("is_degree", "GreedyColoring.swift", "                    if available[y] { heap.lower(y, heap.key[y] - 1) }", "", mode="stmt"),
    Mutant("is_presetblock", "GreedyColoring.swift", "                for k in rows.offsets[x] ..< rows.offsets[x + 1] { available[rows.neighbors[k]] = false }", "", mode="stmt"),
    Mutant("is_presetclass", "GreedyColoring.swift", "colors[presets[nextPreset]] <= color", "colors[presets[nextPreset]] < color"),
    Mutant("is_compact", "GreedyColoring.swift", "        swap(&adjacency, &spare)", "", mode="stmt"),

    # Connected sequential
    Mutant("cs_swap", "GreedyColoring.swift", "depthFirst", "!depthFirst", nth=1),
    Mutant("cs_bfsroot", "GreedyColoring.swift", "order.count - 1", "order.count", nth=0),
    Mutant("cs_bfsseen", "GreedyColoring.swift", "                    seen[rows.neighbors[k]] = true", "", mode="stmt"),
    Mutant("cs_dfsdescend", "GreedyColoring.swift", "                stack.append(w)\n                cursor.append(rows.offsets[w])", "", mode="stmt"),

    # Colored neighbours
    Mutant("cn_start", "GreedyColoring.swift", "rows.degree(v) > rows.degree(best)", "rows.degree(v) >= rows.degree(best)"),
    Mutant("cn_count", "GreedyColoring.swift", "            if heap.contains(w) { heap.modify(w, heap.value(w) + 1) }", "", mode="stmt"),
    Mutant("cn_sorted", "GreedyColoring.swift", "sorted[k]", "rows.neighbors[k]"),
    Mutant("cn_presetcount", "GreedyColoring.swift", "            for k in rows.offsets[v] ..< rows.offsets[v + 1] where colors[rows.neighbors[k]] >= 0 { count += 1 }", "", mode="stmt"),

    # greedyColoring(strategy:presetColor:) and greedyColoring(order:)
    Mutant("preset_negative", "GreedyColoring.swift", r'                precondition(c >= 0, "The preset colour of \(vertex) is negative")', "", mode="stmt"),
    Mutant("preset_adjacent", "GreedyColoring.swift", '                precondition(preset[rows.neighbors[k]] != preset[v], "Two adjacent vertices have the same preset colour")', "", mode="stmt"),
    Mutant("order_twice", "GreedyColoring.swift", r'            precondition(!seen[v], "\(vertex) appears twice in the order")', "", mode="stmt"),
    Mutant("order_seen", "GreedyColoring.swift", "            seen[v] = true", "", mode="stmt"),
    Mutant("order_missing", "GreedyColoring.swift", r'        precondition(sequence.count == n, "The order misses \(n - sequence.count) vertices")', "", mode="stmt"),
    Mutant("order_foreign", "GreedyColoring.swift", r'                precondition(v >= 0 && v < n && self.vertex(atIndex: v) == vertex, "\(vertex) in the order is not a vertex of the graph")', "", mode="stmt"),

    # First fit in a given order, over the graph's own rows
    Mutant("ffrows_mark", "GreedyColoring.swift", "                if c >= 0 { used[c] = v }", "", mode="stmt"),
    Mutant("ffrows_skip", "GreedyColoring.swift", "            while used[c] == v { c += 1 }", "            while used[c] == v || c == 1 { c += 1 }", mode="stmt"),

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
    Mutant("ends_loop", "EdgeColoring.swift", '                precondition(w != v, "edgeColoring() requires a simple graph: the graph has a self-loop")', "", mode="stmt"),
    Mutant("ends_parallel", "EdgeColoring.swift", "                stamp[w] = v", "", mode="stmt"),

    # The colour → edge tables
    Mutant("table_rows", "EdgeColoring.swift", "width <= 2 * capacity", "true"),
    Mutant("table_probe", "EdgeColoring.swift", "            h = (h &+ 1) & m", "            h = (h &+ 2) & m", mode="stmt"),
    Mutant("table_key", "EdgeColoring.swift", "        if !isRow(x) { keys[i] = Int32(truncatingIfNeeded: c) }", "", mode="stmt"),
    Mutant("table_stays", "EdgeColoring.swift", "            if stays { continue }", "", mode="stmt"),
    Mutant("table_wrap", "EdgeColoring.swift", "hole <= j ? (hole < home && home <= j) : (hole < home || home <= j)", "hole < home && home <= j"),
    Mutant("table_low", "EdgeColoring.swift", "        if c < low[x] { low[x] = Int32(truncatingIfNeeded: c) }", "", mode="stmt"),
    Mutant("table_other", "EdgeColoring.swift", "Int(first[e] ^ second[e]) ^ x", "Int(first[e])"),
    Mutant("flip_alternate", "EdgeColoring.swift", "            c = c == c1 ? c2 : c1", "            c = c1", mode="stmt"),
    Mutant("flip_recolor", "EdgeColoring.swift", "            next = next == c1 ? c2 : c1", "            next = c2", mode="stmt"),

    # Misra–Gries
    Mutant("mg_fanfree", "EdgeColoring.swift", "table.isFree(last, k)", "true", nth=0),
    Mutant("mg_fanfree_table", "EdgeColoring.swift", "table.isFree(last, k)", "true", nth=1),
    Mutant("mg_fanrepeat", "EdgeColoring.swift", "inFan[table.other(f, u)] != e", "true", nth=0),
    Mutant("mg_fanrepeat_table", "EdgeColoring.swift", "inFan[table.other(f, u)] != e", "true", nth=1),
    Mutant("mg_fanleast", "EdgeColoring.swift", "k < least", "true"),
    Mutant("mg_fanmark", "EdgeColoring.swift", "                inFan[x] = e", "", mode="stmt"),
    Mutant("mg_cfree", "EdgeColoring.swift", "table.isFree(fan[fan.count - 1], c)", "false", nth=1),
    Mutant("mg_flip", "EdgeColoring.swift", "                table.flip(from: u, d, c)", "", mode="stmt"),
    Mutant("mg_rotate", "EdgeColoring.swift", "            while !table.isFree(fan[w], d) { w += 1 }", "", mode="stmt"),
    Mutant("mg_shift", "EdgeColoring.swift", "            for j in 0 ..< w { shifted.append(Int(table.color[fanEdges[j + 1]])) }", "            for j in 0 ..< w { shifted.append(Int(table.color[fanEdges[j]])) }", mode="stmt"),
    Mutant("mg_last", "EdgeColoring.swift", "            table.set(fanEdges[w], d)", "            table.set(fanEdges[w], c)", mode="stmt"),

    # König
    Mutant("konig_bipartite", "EdgeColoring.swift", "        guard _TwoColoring(witness: false).run(count: n, edgeCount: m, &rows).sides != nil else { return nil }", "", mode="stmt"),
    Mutant("konig_flip", "EdgeColoring.swift", "            if !table.isFree(v, a) { table.flip(from: v, a, b) }", "", mode="stmt"),
    Mutant("konig_color", "EdgeColoring.swift", "            table.set(e, a)", "            table.set(e, b)", mode="stmt"),

    # The greedy edge colouring
    Mutant("ge_loops", "EdgeColoring.swift", "        for e in 0 ..< m where first[e] == second[e] { degree[Int(first[e])] -= 1 }", "", mode="stmt"),
    Mutant("ge_loopmet", "EdgeColoring.swift", "u == v ? degree[u] - 1 : degree[u] + degree[v] - 2", "degree[u] + degree[v] - 2"),
    Mutant("ge_order", "EdgeColoring.swift", "            order[starts[top - met[e]]] = e", "            order[e] = e", mode="stmt"),
    Mutant("ge_free", "EdgeColoring.swift", "!table.isFree(u, c) || !table.isFree(v, c)", "!table.isFree(u, c)"),
    Mutant("ge_low", "EdgeColoring.swift", "            if c == table.low[u] { table.low[u] += 1 }", "            table.low[u] = Int32(c + 1)", mode="stmt"),

    # Checks
    Mutant("check_loop", "ColoringChecks.swift", "w != v && colors[w] == c", "colors[w] == c"),
    Mutant("check_holder", "ColoringChecks.swift", "                    if holder[c] != e { return false }", "", mode="stmt"),
    Mutant("check_loopedge", "ColoringChecks.swift", "holder[c] != e", "true"),
    Mutant("check_dense", "ColoringChecks.swift", "low < 0 || high >= 2 * m + 1", "high >= 2 * m + 1"),

    # Exact search: components, whole-graph cases, per-component handling and skipping
    Mutant("exact_edgeless", "ExactColoring.swift", "    guard !rows.neighbors.isEmpty else { return (1, colors) }", "", mode="stmt"),
    Mutant("exact_wholesides", "ExactColoring.swift", "Int(sides[v])", "1 - Int(sides[v])"),
    Mutant("exact_partsides", "ExactColoring.swift", "Int(sides[i])", "1 - Int(sides[i])"),
    Mutant("exact_components", "ExactColoring.swift", "                component[rows.neighbors[k]] = count", "", mode="stmt"),
    Mutant("exact_skip", "ExactColoring.swift", "upper > floor", "upper > floor + 1"),
    Mutant("exact_noskip", "ExactColoring.swift", "lexicographic ? 0 : chi", "0"),
    Mutant("exact_load", "ExactColoring.swift", "local[global.neighbors[k]] >= 0", "true"),
    Mutant("exact_witness", "ExactColoring.swift", "            for (i, v) in part.enumerated() { colors[v] = witness[i] }", "", mode="stmt"),
    Mutant("exact_renumber", "ExactColoring.swift", "            colors[v] = renumbered[c]", "", mode="stmt"),

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
    Mutant("bb_prefer", "ExactColoring.swift", "after == first ? 0 : after + 1", "after + 1"),

    # Exact search: conflict-directed backjumping
    Mutant("cbj_blockers", "ExactColoring.swift", "            if c >= 0 && c <= limit { holder[c] = min(holder[c], level[w]) }", "", mode="stmt"),
    Mutant("cbj_latest", "ExactColoring.swift", "            for f in failure where f > j { j = f }", "            j = failure.min() ?? -1", mode="stmt"),
    Mutant("cbj_merge", "ExactColoring.swift", "                frameConflict[j].append(f)", "", mode="stmt"),
    Mutant("cbj_level", "ExactColoring.swift", "                level[v] = t", "", mode="stmt"),

    # Exact search: the lexicographic pass
    Mutant("lex_fastpath", "ExactColoring.swift", "        if !fit.contains(where: { $0 >= chi }) { return fit }", "", mode="stmt"),
    Mutant("lex_clash", "ExactColoring.swift", "                    clash = true", "", mode="stmt"),
    Mutant("kempe_fixed", "ExactColoring.swift", "                    if x < v { fixed = true }", "", mode="stmt"),
    Mutant("kempe_chain", "ExactColoring.swift", "witness[y] != c && witness[y] != d", "witness[y] != c"),
    Mutant("kempe_swap", "ExactColoring.swift", "                    for x in queue { witness[x] = witness[x] == c ? d : c }", "", mode="stmt"),
    Mutant("kempe_chosen", "ExactColoring.swift", "                    chosen = c", "", mode="stmt", nth=0),
    Mutant("region_prefix", "ExactColoring.swift", "y <= v ? preset[y] : -1", "y < v ? preset[y] : -1"),
    Mutant("region_witness", "ExactColoring.swift", "                    for (j, y) in members.enumerated() where y > v { witness[y] = region.color[j] }", "", mode="stmt"),
    Mutant("region_chosen", "ExactColoring.swift", "                    chosen = c", "", mode="stmt", nth=1),
    Mutant("lex_high", "ExactColoring.swift", "            high = max(high, chosen)", "", mode="stmt"),
    Mutant("lex_initial", "ExactColoring.swift", "        _restrictGrowth(&witness, from: 0, high: -1, scratch: &scratch)", "", mode="stmt"),
    Mutant("lex_keep", "ExactColoring.swift", "        if c <= high { continue }", "", mode="stmt"),
]
