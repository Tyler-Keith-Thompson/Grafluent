# Planted bugs for Tours; run with `just mutate Tours`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   hz_cursor            the undirected cursor left on the edge just taken: the next scan meets it
#                        first, skips it by its used bit, and takes the same next edge.
#   hr_parallel, hr_loops, hs_init_out, hp_dsoft, hs_init_count, hp_back_count
#                        the Hamiltonian pruning only cuts subtrees without a solution, so a weaker
#                        prune finds the same first solution. Parallel copies or self-loops in the
#                        distinct rows only overcount f (and `others`, so the skip rule skips less);
#                        not subtracting the start from a path's successor counts, or never
#                        counting directed soft vertices, overcounts too. Without the initial
#                        counts, only vertices that are dead at the root go uncounted, and a dead
#                        vertex at the root means no solution at all (cycles: f < 2; paths: a
#                        non-end with f < 2, or an isolated vertex); entering one later still makes
#                        the count negative and the state non-viable. Without re-adding y on the
#                        way back, only a soft y is lost (y cannot be dead: the search stands on
#                        viable states, dead == 0), so soft drifts down: a weaker prune.
#   hr_reach_none        the search never asks for reachability with every vertex visited: the skip
#                        rule covers the last step (the old end then has no other unvisited
#                        neighbour), and an undirected cycle leaves its start with n − 2 ≥ 1 left.
#                        Kept so the helper answers right on its own.
#   hr_skip_never, hr_skip_one
#                        the skip rule: never skipping only searches more; skipping also when the
#                        old end has one other unvisited neighbour only delays the cut, since the
#                        next step that leaves a branch runs the search and finds the stranded part
#                        (the degree rules catch a stranded single vertex or pair at once). Slower
#                        or the same; the same first solution.
#   sb_get_check, sb_set_check
#                        _SearchBuffer's bounds checks: every index the search uses is in range.
#   hs_target_early      entering the target before the last step: the degree rule already cuts it,
#                        since a path's last vertex other than the target then has f = 1 < 2.
#   hs_parallel_retry    retrying a parallel copy from the same frame explores the same failed
#                        subtree again: slower, the same result.
#   to_row_nonpositive   a move of gain zero is never better than the best so far (at least zero).
#   to_rows_all          rescanning the rows after q too: their columns are all past q, unchanged,
#                        so the full rescan finds the same best move.
#   to_count             a tour of fewer vertices than the graph also traps without the count check,
#                        on the tour buffer's checked subscript in a debug build; in an optimized
#                        build that subscript is unchecked, and this precondition is the only trap.
#   hk_complete_path_off the validity path on a complete graph: every flag is true, the same table.
#   hk_undirected_transposed
#                        the transpose of a symmetric matrix is the matrix.
#   hk_lost              the reconstruction always finds its next vertex: each step recomputes the
#                        sum the table formed from the same two operands (addition is commutative,
#                        also in floating point), so the equality holds exactly. Kept as a guard.
#   hk_size_strict       a stricter memory bound (4 bytes per entry more): the first size it would
#                        newly refuse is 25 vertices with 8-byte weights, whose table is 3.6 GB; no
#                        test can run that, and the looser mutants are not planted, since a 26-vertex
#                        test would then allocate 7 GB.
#   ch_check             Christofides' own finite-weight check before its bound: a NaN or infinite
#                        weight fails the bound (NaN compares false, ∞ is past it) and traps there,
#                        and the matrix checks again; the first check gives the clearer message.

TESTS = ["ToursTests"]

MUTANTS = [
    # Hierholzer, undirected: the used bit, the cursor, the splice into the output
    Mutant("hz_used", "Eulerian.swift", "!used[f]", "true"),
    Mutant("hz_mark", "Eulerian.swift", "            used[e] = true", "", mode="stmt"),
    Mutant("hz_cursor", "Eulerian.swift", "            cursor[v] = k &+ 1", "            cursor[v] = k", mode="stmt", nth=0),
    Mutant("hz_skip_first", "Eulerian.swift", "cursor[v]", "cursor[v] == 0 && rows.count(v) > 1 ? 1 : cursor[v]", nth=0),
    Mutant("hz_splice", "Eulerian.swift", "            if top > 0 { edges[out &- 1] = edges[top &- 1] }", "", mode="stmt", nth=0),
    # Hierholzer, directed
    Mutant("hzd_cursor", "Eulerian.swift", "            cursor[v] = k &+ 1", "            cursor[v] = k", mode="stmt", nth=1),
    Mutant("hzd_splice", "Eulerian.swift", "            if top > 0 { edges[out &- 1] = edges[top &- 1] }", "", mode="stmt", nth=1),
    Mutant("hzd_last_slot", "Eulerian.swift", "k < offsets[v &+ 1]", "k < offsets[v &+ 1] - 1"),
    # Collecting the walk
    Mutant("collect_closed", "Eulerian.swift", "closed ? m : m + 1", "m + 1"),
    Mutant("collect_missed", "Eulerian.swift", "    guard walk(vertices, edges) == 0 else { return nil }", "    _ = walk(vertices, edges)", mode="stmt"),
    # Start rules
    Mutant("start_circuit_on_trail", "Eulerian.swift", "(request, shape)", "(request == .circuit ? _EulerianRequest.trail : request, shape)"),
    Mutant("start_ignored", "Eulerian.swift", "start < 0 ? first : start", "first"),
    Mutant("start_from_any", "Eulerian.swift", "start < 0 ? trailStart : (isTrailStart ? start : -1)", "start < 0 ? trailStart : start"),
    Mutant("start_odd_u", "Eulerian.swift", "start >= 0 && rows.count(start) & 1 != 0", "start >= 0"),
    Mutant("start_trail_d", "Eulerian.swift", "start >= 0 && start == degrees.trailStart", "start >= 0"),
    # The empty and edgeless graphs
    Mutant("empty_eulerian_u", "Eulerian.swift", "            answer.isEulerian = true", "", mode="stmt", nth=0),
    Mutant("empty_eulerian_d", "Eulerian.swift", "        answer.isEulerian = true", "", mode="stmt", nth=1),
    Mutant("edgeless_trail_u", "Eulerian.swift", "            if request == .trail, n > 0 { answer.walk = ([Swift.max(start, 0)], []) }", "", mode="stmt"),
    Mutant("edgeless_nvertex_d", "Eulerian.swift", "        if request == .trail, n > 0 { answer.walk = ([Swift.max(start, 0)], []) }", "        if request == .trail { answer.walk = ([Swift.max(start, 0)], []) }", mode="stmt", nth=1),
    Mutant("edgeless_start_u", "Eulerian.swift", "Swift.max(start, 0)", "0", nth=0),
    Mutant("edgeless_start_d", "Eulerian.swift", "Swift.max(start, 0)", "0", nth=2),
    # Undirected degrees and connectivity
    Mutant("deg_isolated_u", "Eulerian.swift", "d > 0", "true"),
    Mutant("deg_first_last_u", "Eulerian.swift", "                if degrees.first < 0 { degrees.first = v }", "                degrees.first = v", mode="stmt"),
    Mutant("deg_trailstart_last_u", "Eulerian.swift", "                if degrees.trailStart < 0 { degrees.trailStart = v }", "                degrees.trailStart = v", mode="stmt"),
    Mutant("deg_any_odd_u", "Eulerian.swift", "odd == 0 ? 0 : odd == 2 ? 1 : -1", "odd == 0 ? 0 : 1"),
    Mutant("deg_shape_guard_u", "Eulerian.swift", "            guard degrees.shape >= 0 else { return answer }", "", mode="stmt", nth=0),
    Mutant("conn_off_u", "Eulerian.swift", "_undirectedReach(&rows, count: n, from: degrees.first) == degrees.withEdges", "true"),
    Mutant("reach_generic", "Eulerian.swift", "                reached &+= 1", "", mode="stmt", nth=0),
    Mutant("reach_stored", "Eulerian.swift", "                reached &+= 1", "", mode="stmt", nth=1),
    Mutant("reach_stored_row", "Eulerian.swift", "first &+ rows[3 &* v &+ 1]", "first &+ rows[3 &* v &+ 1] &- 1"),
    # Directed degrees and connectivity
    Mutant("deg_in_d", "Eulerian.swift", "        balance[w] &-= 1", "", mode="stmt"),
    Mutant("deg_inonly_d", "Eulerian.swift", "        hasEdges[w] = true", "", mode="stmt"),
    Mutant("deg_first_last_d", "Eulerian.swift", "            if degrees.first < 0 { degrees.first = v }", "            degrees.first = v", mode="stmt", nth=1),
    Mutant("deg_trailstart_d", "Eulerian.swift", "            degrees.trailStart = v", "", mode="stmt", nth=1),
    Mutant("deg_other_d", "Eulerian.swift", "other == 0 && plus == 1 && minus == 1 ? 1 : -1", "plus == 1 && minus == 1 ? 1 : -1"),
    Mutant("deg_shape_guard_d", "Eulerian.swift", "        guard degrees.shape >= 0 else { return answer }", "", mode="stmt", nth=1),
    Mutant("conn_off_d", "Eulerian.swift", "_directedReach(offsets, targets, from: degrees.shape == 0 ? degrees.first : degrees.trailStart) == degrees.withEdges", "true"),
    Mutant("conn_from_first_d", "Eulerian.swift", "degrees.shape == 0 ? degrees.first : degrees.trailStart", "degrees.first"),
    Mutant("reach_directed", "Eulerian.swift", "                reached &+= 1", "", mode="stmt", nth=2),
    # The simple graph a tour reads
    # Hamiltonian rows and the search's setup
    Mutant("hr_parallel", "Hamiltonian.swift", "                if w == v || stamp[w] == v { continue }", "                if w == v { continue }", mode="stmt"),
    Mutant("hr_loops", "Hamiltonian.swift", "                if w == v || stamp[w] == v { continue }", "                if stamp[w] == v { continue }", mode="stmt"),
    Mutant("hs_pruned_two", "Hamiltonian.swift", "n >= 3", "n >= 2"),
    Mutant("hs_init_count", "Hamiltonian.swift", "            count(u, 1)", "", mode="stmt", nth=0),
    Mutant("hs_init_out", "Hamiltonian.swift", "                    for k in rows.nextOffsets[u] ..< rows.nextOffsets[u + 1] where rows.next[k] == start { out -= 1 }", "", mode="stmt"),
    # Pruning: the counts
    Mutant("hp_target_one", "Hamiltonian.swift", "isTarget ? 1 : 2", "2"),
    Mutant("hp_soft", "Hamiltonian.swift", "soft <= 1", "soft <= 0"),
    Mutant("hp_dtarget", "Hamiltonian.swift", "target >= 0 && !isTarget", "target >= 0"),
    Mutant("hp_dsoft", "Hamiltonian.swift", "freeOut[u] < 1 && !cycle && target < 0", "false"),
    Mutant("hp_path_startpred", "Hamiltonian.swift", "!cycle || unvisited == 0 || startPredecessors > 0", "unvisited == 0 || startPredecessors > 0"),
    Mutant("hp_startpred_back", "Hamiltonian.swift", "            if cycle && isStartPredecessor[y] { startPredecessors += 1 }", "", mode="stmt"),
    Mutant("hp_cycle_start", "Hamiltonian.swift", "!(cycle && p == start)", "true"),
    Mutant("hp_free_d", "Hamiltonian.swift", "                free[u] -= sign", "                free[u] -= 2 * sign", mode="stmt", nth=0),
    Mutant("hp_freeout_d", "Hamiltonian.swift", "                freeOut[u] -= sign", "                freeOut[u] -= 2 * sign", mode="stmt"),
    Mutant("hp_free_u", "Hamiltonian.swift", "                free[u] -= sign", "                free[u] -= 2 * sign", mode="stmt", nth=1),
    Mutant("hp_back_count", "Hamiltonian.swift", "            count(y, 1)", "", mode="stmt"),
    # Pruning: reachability
    Mutant("hr_reach_found", "Hamiltonian.swift", "                if reached == unvisited { return true }", "", mode="stmt"),
    Mutant("sb_get_check", "Hamiltonian.swift", "            precondition(UInt(bitPattern: i) < UInt(bitPattern: count), \"Index out of range\")", "", mode="stmt", nth=0),
    Mutant("sb_set_check", "Hamiltonian.swift", "            precondition(UInt(bitPattern: i) < UInt(bitPattern: count), \"Index out of range\")", "", mode="stmt", nth=1),
    Mutant("hr_reach_none", "Hamiltonian.swift", "        guard unvisited > 0 else { return true }", "", mode="stmt"),
    Mutant("hr_reach_off", "Hamiltonian.swift", "isViable && (others == 0 || reachesAll(from: x))", "isViable"),
    Mutant("hr_skip_never", "Hamiltonian.swift", "others == 0 || reachesAll(from: x)", "reachesAll(from: x)"),
    Mutant("hr_skip_one", "Hamiltonian.swift", "others == 0 || reachesAll(from: x)", "others <= 1 || reachesAll(from: x)", nth=0),
    Mutant("hr_others_d", "Hamiltonian.swift", "                others += 1", "", mode="stmt", nth=0),
    Mutant("hr_others_u", "Hamiltonian.swift", "                others += 1", "", mode="stmt", nth=1),
    # The search order and the closing edge
    Mutant("hs_one_loop", "Hamiltonian.swift", "            for k in rows.rowOffsets[s] ..< rows.rowOffsets[s + 1] where rows.rowTargets[k] == s { return ([s], [rows.rowEdges[k]]) }", "", mode="stmt"),
    Mutant("hs_same_edge", "Hamiltonian.swift", "                        if depth == 1 && e == pathEdges[0] { continue }", "", mode="stmt"),
    Mutant("hs_target_early", "Hamiltonian.swift", "visited[x] || (x == target && depth + 1 != n - 1) || tried[x] == frame[depth]", "visited[x] || tried[x] == frame[depth]"),
    Mutant("hs_parallel_retry", "Hamiltonian.swift", "visited[x] || (x == target && depth + 1 != n - 1) || tried[x] == frame[depth]", "visited[x] || (x == target && depth + 1 != n - 1)", nth=0),
    Mutant("hs_frame", "Hamiltonian.swift", "                        frame[depth] = frames", "", mode="stmt"),
    Mutant("hs_cursor", "Hamiltonian.swift", "                        cursor[depth] = k", "", mode="stmt"),
    Mutant("hs_backtrack", "Hamiltonian.swift", "            if depth > 0 { move(from: path[depth - 1], to: v, -1) }", "", mode="stmt"),
    Mutant("hs_same_start_end", "Hamiltonian.swift", "        if target == s { return nil }", "", mode="stmt"),
    Mutant("hs_first_start_only", "Hamiltonian.swift", "start < 0 ? 0 ..< n : start ..< start + 1", "start < 0 ? 0 ..< 1 : start ..< start + 1"),
    Mutant("hs_cycle_empty", "Hamiltonian.swift", "        guard count > 0 else { return nil }", "", mode="stmt"),
    # The simple graph a tour reads
    Mutant("tm_loops", "TourMatrix.swift", "u != v", "true", nth=0),
    Mutant("tm_loops_d", "TourMatrix.swift", "u != v", "true", nth=1),
    Mutant("tm_check", "TourMatrix.swift", "                _checkTourWeight(w)", "", mode="stmt", nth=0),
    Mutant("tm_check_d", "TourMatrix.swift", "                _checkTourWeight(w)", "", mode="stmt", nth=1),
    Mutant("tm_check_infinite", "TourMatrix.swift", "!(w - w == .zero)", "!(w == w)"),
    Mutant("tm_first_copy", "TourMatrix.swift", "edges[cell] < 0 || w < weights[cell]", "edges[cell] < 0", nth=0),
    Mutant("tm_latest_tie", "TourMatrix.swift", "edges[cell] < 0 || w < weights[cell]", "edges[cell] < 0 || w <= weights[cell]", nth=0),
    Mutant("tm_first_copy_d", "TourMatrix.swift", "edges[cell] < 0 || w < weights[cell]", "edges[cell] < 0", nth=1),
    Mutant("tm_latest_tie_d", "TourMatrix.swift", "edges[cell] < 0 || w < weights[cell]", "edges[cell] < 0 || w <= weights[cell]", nth=1),
    Mutant("tm_arc_close", "TourMatrix.swift", "order[$0 + 1 == n ? 0 : $0 + 1]", "order[$0 + 1 == n ? 1 : $0 + 1]"),
    Mutant("tm_symmetric_weight", "TourMatrix.swift", "                    weights[v * n + u] = w", "", mode="stmt"),
    Mutant("tm_symmetric_edge", "TourMatrix.swift", "                    edges[v * n + u] = e", "", mode="stmt"),
    Mutant("tm_close", "TourMatrix.swift", "order[i + 1 == n ? 0 : i + 1]", "order[i + 1 == n ? 1 : i + 1]"),
    # Nearest neighbour
    Mutant("nn_last_tie", "NearestNeighbor.swift", "w < nearest", "w <= nearest"),
    Mutant("nn_swap_remove", "NearestNeighbor.swift", "                    for k in best ..< left { unvisited[k] = unvisited[k + 1] }", "                    unvisited[best] = unvisited[left]", mode="stmt"),
    Mutant("nn_reverse_order", "NearestNeighbor.swift", "v < start ? v : v - 1", "n - 2 - (v < start ? v : v - 1)"),
    Mutant("nn_start_ignored", "NearestNeighbor.swift", "_nearestNeighborOrder(matrix, from: s)", "_nearestNeighborOrder(matrix, from: 0)"),
    Mutant("nn_small", "NearestNeighbor.swift", "n >= 3", "n >= 2"),
    # 2-opt: the row scan and the choice of move
    Mutant("to_row_last_tie", "TwoOpt.swift", "gain > best", "gain >= best"),
    Mutant("to_row_nonpositive", "TwoOpt.swift", "added < current", "added <= current"),
    Mutant("to_best_last_row", "TwoOpt.swift", "                for i in 0 ..< n - 2 where rowColumn[i] >= 0 && (p < 0 || rowGain[i] > rowGain[p]) { p = i }", "                for i in 0 ..< n - 2 where rowColumn[i] >= 0 && (p < 0 || rowGain[i] >= rowGain[p]) { p = i }", mode="stmt"),
    Mutant("to_first_improving", "TwoOpt.swift", "                for i in 0 ..< n - 2 where rowColumn[i] >= 0 && (p < 0 || rowGain[i] > rowGain[p]) { p = i }", "                for i in 0 ..< n - 2 where rowColumn[i] >= 0 && p < 0 { p = i }", mode="stmt"),
    Mutant("to_reverse", "TwoOpt.swift", "                    t.swapAt(lo, hi)", "", mode="stmt"),
    # 2-opt: the incremental rescan
    Mutant("to_along_first", "TwoOpt.swift", "                for k in p ... q { along[k] = d[t[k] * n + t[k + 1]] }", "                for k in p + 1 ... q { along[k] = d[t[k] * n + t[k + 1]] }", mode="stmt"),
    Mutant("to_along_last", "TwoOpt.swift", "                for k in p ... q { along[k] = d[t[k] * n + t[k + 1]] }", "                for k in p ..< q { along[k] = d[t[k] * n + t[k + 1]] }", mode="stmt"),
    Mutant("to_rows_q", "TwoOpt.swift", "Swift.min(q + 1, n - 2)", "Swift.min(q, n - 2)"),
    Mutant("to_rows_all", "TwoOpt.swift", "Swift.min(q + 1, n - 2)", "n - 2", nth=0),
    Mutant("to_stale_best", "TwoOpt.swift", "i >= p || (rowColumn[i] >= p && rowColumn[i] <= q)", "i >= p"),
    Mutant("to_stale_q", "TwoOpt.swift", "rowColumn[i] <= q", "rowColumn[i] < q"),
    Mutant("to_first_column", "TwoOpt.swift", "Swift.max(p, i + 2)", "Swift.max(p + 1, i + 2)"),
    Mutant("to_keep_never", "TwoOpt.swift", "gain > rowGain[i] || (gain == rowGain[i] && column < old)", "false"),
    Mutant("to_keep_tie", "TwoOpt.swift", "column < old", "column > old"),
    # 2-opt: the entry points
    Mutant("to_small", "TwoOpt.swift", "n >= 3", "n >= 2", nth=0),
    Mutant("to_small_improving", "TwoOpt.swift", "n >= 3", "n >= 2", nth=1),
    Mutant("to_from_identity", "TwoOpt.swift", "_twoOpt(matrix, _nearestNeighborOrder(matrix, from: 0))", "_twoOpt(matrix, Array(0 ..< n))"),
    Mutant("to_count", "TwoOpt.swift", "        precondition(tour.vertices.count == n, \"The tour does not list every vertex once\")", "", mode="stmt"),
    # Held–Karp
    Mutant("hk_complete_path_off", "HeldKarp.swift", "    for u in 0 ..< n where complete {\n        for v in 0 ..< n where u != v && matrix.edges[u * n + v] < 0 {\n            complete = false\n            break\n        }\n    }", "    complete = false", mode="stmt"),
    Mutant("hk_complete_always", "HeldKarp.swift", "    for u in 0 ..< n where complete {\n        for v in 0 ..< n where u != v && matrix.edges[u * n + v] < 0 {\n            complete = false\n            break\n        }\n    }", "", mode="stmt"),
    Mutant("hk_complete_symmetric", "HeldKarp.swift", "    for u in 0 ..< n where complete {\n        for v in 0 ..< n where u != v && matrix.edges[u * n + v] < 0 {\n            complete = false\n            break\n        }\n    }", "    for u in 0 ..< n where complete {\n        for v in u + 1 ..< n where matrix.edges[u * n + v] < 0 {\n            complete = false\n            break\n        }\n    }", mode="stmt"),
    Mutant("hk_transpose_weights", "HeldKarp.swift", "                transposedWeights[u * n + v] = matrix.weights[v * n + u]", "", mode="stmt"),
    Mutant("hk_transpose_edges", "HeldKarp.swift", "                transposedEdges[u * n + v] = matrix.edges[v * n + u]", "", mode="stmt"),
    Mutant("hk_directed_untransposed", "HeldKarp.swift", "_heldKarpOrder(matrix, directed: true)", "_heldKarpOrder(matrix, directed: false)"),
    Mutant("hk_undirected_transposed", "HeldKarp.swift", "_heldKarpOrder(matrix, directed: false)", "_heldKarpOrder(matrix, directed: true)", nth=0),
    Mutant("hk_base", "HeldKarp.swift", "d[(b + 1) * n]", "d[(b + 1) * n] + d[(b + 1) * n]"),
    Mutant("hk_max", "HeldKarp.swift", "candidate < least ? candidate : least", "candidate > least ? candidate : least"),
    Mutant("hk_store", "HeldKarp.swift", "                            for j in 0 ..< count { cost[set * k + members[j]] = best[j] }", "", mode="stmt"),
    Mutant("hk_first_tail", "HeldKarp.swift", "                                    for j in 0 ..< count { best[j] = dt[row &+ members[j]] + tail }", "                                    for j in 0 ..< count { best[j] = dt[row &+ members[j]] }", mode="stmt"),
    Mutant("hk_valid_cell", "HeldKarp.swift", "                                guard valid[cell] else { continue }", "", mode="stmt"),
    Mutant("hk_found", "HeldKarp.swift", "found & (1 << j) == 0 || candidate < best[j]", "candidate < best[j]"),
    Mutant("hk_valid_store", "HeldKarp.swift", "                                valid[set * k + members[j]] = true", "", mode="stmt"),
    Mutant("hk_none", "HeldKarp.swift", "any ? least : nil", "least"),
    Mutant("hk_tie_highest", "HeldKarp.swift",
           "        for c in 0 ..< k where set & (1 << c) == 0 && matrix.edges[last * n + c + 1] >= 0 {\n            let cell = ((set | 1 << c) * k) + c\n            guard complete || valid[cell], cost[cell] + matrix.weights[last * n + c + 1] == remaining else { continue }\n            order.append(c + 1)\n            set |= 1 << c\n            last = c + 1\n            remaining = cost[cell]\n            break\n        }",
           "        for c in (0 ..< k).reversed() where set & (1 << c) == 0 && matrix.edges[last * n + c + 1] >= 0 {\n            let cell = ((set | 1 << c) * k) + c\n            guard complete || valid[cell], cost[cell] + matrix.weights[last * n + c + 1] == remaining else { continue }\n            order.append(c + 1)\n            set |= 1 << c\n            last = c + 1\n            remaining = cost[cell]\n            break\n        }",
           mode="stmt"),
    Mutant("hk_remaining", "HeldKarp.swift", "            remaining = cost[cell]", "", mode="stmt", nth=1),
    Mutant("hk_small", "HeldKarp.swift", "n >= 3", "n >= 2", nth=0),
    Mutant("hk_small_d", "HeldKarp.swift", "n >= 3", "n >= 2", nth=1),
    Mutant("hk_lost", "HeldKarp.swift", "    precondition(order.count == n, \"Held–Karp's reconstruction lost the tour\")", "", mode="stmt"),
    Mutant("hk_size_strict", "HeldKarp.swift", "Swift.max(MemoryLayout<W>.stride, 1) + 1", "Swift.max(MemoryLayout<W>.stride, 1) + 4"),
    # Christofides: Prim on the dense matrix
    Mutant("ch_prim_rank", "Christofides.swift", "numbers[$0]", "0"),
    Mutant("ch_prim_row", "Christofides.swift", "(v, row + v)", "(v, v)"),
    Mutant("ch_prim_weight", "Christofides.swift", "d[$0]", ".zero"),
    Mutant("ch_prim_parent", "DensePrim.swift", "                                keyParent[v] = u", "", mode="stmt", module="SpanningTrees"),
    Mutant("ch_degree_parent", "Christofides.swift", "        degree[e.u] += 1", "", mode="stmt"),
    Mutant("ch_tree_sort", "Christofides.swift", "    treeEdges.sort { $0.edge < $1.edge }", "", mode="stmt"),
    # Christofides: the odd vertices and the matching
    Mutant("ch_pair_weight", "Christofides.swift", "d[odd[a] * n + odd[b]]", "d[odd[a] * n + odd[a]]"),
    Mutant("ch_half", "Christofides.swift", "_minimumWeightMatchingEdges(_MatchingGraph(count: k, from: from, to: to), pairWeights, half: half)", "_maximumWeightMatchingEdges(_MatchingGraph(count: k, from: from, to: to), pairWeights, maximumCardinality: true, half: half)"),
    # Christofides: the multigraph and the shortcut
    Mutant("ch_rows_both", "Christofides.swift", "        fill[v] += 1", "", mode="stmt"),
    Mutant("ch_hierholzer_start", "Christofides.swift", "_undirectedHierholzer(&rows, count: n, edgeCount: m, start: 0, vertices: vertices, edges: edges)", "_undirectedHierholzer(&rows, count: n, edgeCount: m, start: n - 1, vertices: vertices, edges: edges)"),
    Mutant("ch_shortcut", "Christofides.swift", "        visited[v] = true", "", mode="stmt"),
    Mutant("ch_small", "Christofides.swift", "n >= 3", "n >= 2"),
    # Christofides: the bounds
    Mutant("ch_check", "Christofides.swift", "            _checkTourWeight(w)", "", mode="stmt"),
    Mutant("ch_bound", "Christofides.swift", "            precondition(bound(w), message)", "", mode="stmt"),
    Mutant("ch_int_limit", "Christofides.swift", "            limit = (quotient - 1) / 2", "            limit = maximum", mode="stmt"),
    Mutant("ch_int_limit_double", "Christofides.swift", "            limit = (quotient - 1) / 2", "            limit = quotient - 1", mode="stmt", nth=0),
    Mutant("ch_vertex_limit", "Christofides.swift", "vertexCount < 3 || quotient > 0", "true"),
    Mutant("ch_int_negative", "Christofides.swift", "w <= $0 && w >= -$0", "w <= $0"),
    Mutant("ch_float_bound", "Christofides.swift", "$0.magnitude <= limit", "true"),

    # reuse pass (B)
    Mutant("tn_indexed_u", "TourRows.swift", "numbering.isIndexed ? nil : numbering.numbers", "numbering.numbers"),
    Mutant("tn_indexed_d", "TourRows.swift", "rows.isIndexed ? nil : rows.numbers", "rows.numbers"),
]
