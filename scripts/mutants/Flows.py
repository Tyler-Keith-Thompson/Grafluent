# Planted bugs for Flows; run with `just mutate Flows`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   di_room             the clamp to the cutoff: connectivity only compares the value with the best
#                       so far, and any value at or past the cutoff loses that comparison.
#   di_level_stop, di_back_last, di_kill, di_current, di_resume
#                       Dinic's pruning: levels past the sink's lead only to dead ends, resuming from
#                       a later saturated arc costs one zero augmentation, a dead vertex's current arc
#                       is already at its row's end, rescanning from the row start or from the source
#                       finds the same admissible arcs. Slower; the same value and canonical cut.
#   pr_push_lower       valid labels give label[w] ≥ label[v] − 1 on every residual arc v → w, so
#                       label[w] < dv is label[w] == dv − 1.
#   pr_gap_off, pr_global_off, pr_out, pr_relabel_current
#                       heuristics: without the gap or periodic global relabelling, allowing label n,
#                       or rescanning the row from its start, push–relabel still ends at a maximum
#                       preflow with the same canonical cut.
#   pr_global_source, p2_source
#                       phase 1 never pushes into the source (its label is n and no label passes n),
#                       so every arc out of the source keeps zero residual: neither reverse search
#                       can reach the source to label it.
#   mf_split_always     carrying every undirected network split (and Edmonds–Karp as its flow both
#                       ways) gives the same value, cut and pinned flow, as documented.
#   mf_split_net, gh_split
#                       _flowNetwork's only caller is Gomory–Hu, on the widened capacities: fixed-width
#                       types run in Int (twice the total fits) or Int128 and never overflow 2c; Float
#                       runs in Double. Only Double itself can pass its range, when c > max / 2, and
#                       then the single pair's reverse residual becomes +∞ instead of c + f: every
#                       comparison with it is the same (an excess is finite, so min(r, excess) is the
#                       excess either way), so the flows' values and cuts are too.
#   ni_parallel_q       a merged parallel edge forgetting its greater scanned connection only
#                       contracts less: the pass has already contracted the edge that caused the merge,
#                       so every phase still contracts something.
#   ni_buckets_off, ho_first_least
#                       the heap instead of the bucket queue is another maximum adjacency order, and
#                       `<=` keeps the last least cut instead of the first: either way a minimum cut,
#                       and which one is documented as unspecified (only that equal inputs agree).
#   ns_mixing_off, ns_initial, ns_initial_capacity
#                       pivot heuristics (arc mixing, LEMON's initial pivots): another pivot order
#                       reaches an optimum too, and which optimum is documented as unspecified.
#   ns_artificial_up    a supply node's artificial arc at cost M rather than 0: tree arcs' costs are
#                       never read (only the entering arc's, in updatePotential), so the run is the
#                       same while the arc is in the tree; it leaves with no flow, and pricing it at
#                       M only makes it less attractive to re-enter, which an optimum with every
#                       artificial arc empty never needs.
#   ns_artificial_blocks
#                       an artificial arc on the second side only blocks when the two artificial arcs
#                       on the cycle carry Int.max between them (the total supply exactly Int.max,
#                       split over two supply subtrees) and a pivot joins those subtrees before any
#                       flow reaches a demand; LEMON's initial pivots enter an arc into each demand
#                       first. Not reached by the suite's Int.max networks (FlowsStressTests) nor by
#                       the fix's 12,000 random problems; not proven unreachable.
#   ut_thread_simple    when thread[vIn] is already uOut the rethreading writes back the same links.
#   mcf_balance         unbalanced supplies leave the root unbalanced, so some artificial arc keeps
#                       flow and the solver returns nil anyway.
#   ev_bound            the first vertex outside a minimum vertex cut X has index at most |X|; once
#                       best = |X|, the indices below it have been tried.
#   ev_successor, ev_undirected, ev_cutoff
#                       a pair joined by an edge, run anyway, has its direct arc of capacity n, so the
#                       flow reaches the cutoff and never beats the best; without the cutoff a pair's
#                       value is its true flow, compared the same way.
#   fe_nan              a NaN capacity fails `c >= 0` next, the same trap with another message.
#   fe_contains_directed, fe_contains_undirected
#                       with vertex indices, vertexIndex(of:) traps on a non-vertex itself.
#
# Dead code the survivors showed, removed: the undirected Edmonds–Karp's `|| against > 0` (at most one
# of the two flows is nonzero), checkRowSums' every-row form and `extra` (no caller), Hao–Orlin's
# reverse arcs into the source set (dormant, never read), and the self-loop zeroing before the
# maximum flows of minimumCostMaximumFlow and directed λ (loops get no residual arcs).

TESTS = ["FlowsTests"]

MUTANTS = [
    # The residual network
    Mutant("rn_loopcount", "ResidualNetwork.swift", "u != v", "true", nth=0),
    Mutant("rn_loopfill", "ResidualNetwork.swift", "if tp == hp { continue }", "", mode="stmt"),
    Mutant("rn_directed", "ResidualNetwork.swift", "symmetric ? c : .zero", ".zero"),
    Mutant("rn_undirected", "ResidualNetwork.swift", "symmetric ? c : .zero", "c", nth=0),
    Mutant("rn_rowsum", "ResidualNetwork.swift", "precondition(!overflow, \"The capacities at a vertex sum past the capacity type's range\")", "", mode="stmt"),
    Mutant("rn_mark_reverse", "ResidualNetwork.swift", "!marks[w] && residual[Int(mate[a])] > .zero", "!marks[w] && residual[a] > .zero"),
    Mutant("rn_mark_seed", "ResidualNetwork.swift", "marks[sink] = true", "", mode="stmt"),
    Mutant("rn_directed_flow", "ResidualNetwork.swift", "a < 0 ? .zero : residual[Int(mate[a])]", "a < 0 ? .zero : residual[a]"),
    Mutant("rn_undirected_flow", "ResidualNetwork.swift", "r <= c ? (c - r, .zero) : (.zero, r - c)", "r <= c ? (.zero, c - r) : (r - c, .zero)"),
    Mutant("rn_reset", "ResidualNetwork.swift", "arcs.update(from: initial!, count: arcCount)", "", mode="stmt"),

    # Edmonds–Karp
    Mutant("ek_residual", "AugmentingPaths.swift", "seen[w] != round && residual[a] > .zero", "seen[w] != round"),
    Mutant("ek_found", "AugmentingPaths.swift", "w == sink", "false", nth=0),
    Mutant("ek_bottleneck", "AugmentingPaths.swift", "if r < delta { delta = r }", "", mode="stmt", nth=0),
    Mutant("ek_reverse", "AugmentingPaths.swift", "residual[Int(mate[a])] += delta", "", mode="stmt", nth=0),

    # Dinic
    Mutant("di_cutoff", "AugmentingPaths.swift", "if let cutoff, value >= cutoff { break }", "", mode="stmt"),
    Mutant("di_cutoff_blocking", "AugmentingPaths.swift", "if let cutoff, value >= cutoff { break blocking }", "", mode="stmt"),
    Mutant("di_room", "AugmentingPaths.swift", "if room < delta { delta = room }", "", mode="stmt"),
    Mutant("di_level_stop", "AugmentingPaths.swift", "if d > sinkLevel { break }", "", mode="stmt"),
    Mutant("di_level_residual", "AugmentingPaths.swift", "level[w] < 0 && residual[a] > .zero", "level[w] < 0"),
    Mutant("di_level_reset", "AugmentingPaths.swift", "level.update(repeating: -1, count: n)", "", mode="stmt"),
    Mutant("di_bottleneck", "AugmentingPaths.swift", "if r < delta { delta = r }", "", mode="stmt", nth=1),
    Mutant("di_back", "AugmentingPaths.swift", "if back == depth && residual[a] == .zero { back = k }", "", mode="stmt"),
    Mutant("di_back_last", "AugmentingPaths.swift", "back == depth && residual[a] == .zero", "residual[a] == .zero"),
    Mutant("di_admissible", "AugmentingPaths.swift", "residual[a] > .zero && level[Int(head[a])] == target", "residual[a] > .zero"),
    Mutant("di_kill", "AugmentingPaths.swift", "level[v] = -1", "", mode="stmt"),
    Mutant("di_current", "AugmentingPaths.swift", "current[v] = a", "", mode="stmt"),
    Mutant("di_resume", "AugmentingPaths.swift", "v = depth == 0 ? source : Int(head[path[depth &- 1]])", "depth = 0\n                v = source", mode="stmt"),

    # Edmonds–Karp on undirected networks near the type's maximum
    Mutant("eku_positive_swap", "AugmentingPaths.swift", "alongArc[x] ? along[p] < c : against[p] < c", "alongArc[x] ? against[p] < c : along[p] < c"),
    Mutant("eku_positive_full", "AugmentingPaths.swift", "alongArc[x] ? along[p] < c : against[p] < c", "alongArc[x] ? along[p] <= c : against[p] <= c", nth=0),
    Mutant("eku_own", "AugmentingPaths.swift", "if own >= limit { return limit }", "", mode="stmt"),
    Mutant("eku_other", "AugmentingPaths.swift", "if other >= limit - own { return limit }", "", mode="stmt"),
    Mutant("eku_cancel_along", "AugmentingPaths.swift", "against[p] < delta ? against[p] : delta", ".zero"),
    Mutant("eku_cancel_against", "AugmentingPaths.swift", "along[p] < delta ? along[p] : delta", ".zero"),
    Mutant("eku_sinkside", "AugmentingPaths.swift", "positive(Int(mate[a]), along, against)", "positive(a, along, against)"),
    Mutant("eku_direction", "AugmentingPaths.swift", "alongArc[a] = true", "", mode="stmt"),

    # Push–relabel, phase 1
    Mutant("pr_saturate_reverse", "PushRelabel.swift", "residual[Int(mate[a])] += r", "", mode="stmt"),
    Mutant("pr_saturate_excess", "PushRelabel.swift", "excess[Int(head[a])] += r", "", mode="stmt"),
    Mutant("pr_push_lower", "PushRelabel.swift", "label[w] == below", "label[w] < dv", nth=0),
    Mutant("pr_activate", "PushRelabel.swift", "w != sink && excess[w] == .zero", "w != sink"),
    Mutant("pr_amax", "PushRelabel.swift", "if below > aMax { aMax = below }", "", mode="stmt", nth=0),
    Mutant("pr_inactive", "PushRelabel.swift", "inactive[dv] = v", "", mode="stmt"),
    Mutant("pr_gap_active", "PushRelabel.swift", "active[dv] < 0 && inactive[dv] < 0", "inactive[dv] < 0"),
    Mutant("pr_gap_off", "PushRelabel.swift", "active[dv] < 0 && inactive[dv] < 0", "false", nth=0),
    Mutant("pr_gap_above", "PushRelabel.swift", "label[u] = n", "", mode="stmt"),
    Mutant("pr_out", "PushRelabel.swift", "lowest &+ 1 >= n", "lowest &+ 1 > n", nth=0),
    Mutant("pr_relabel_current", "PushRelabel.swift", "current[v] = lowestArc", "current[v] = rowStart", mode="stmt", nth=0),
    Mutant("pr_global_off", "PushRelabel.swift", "work > threshold", "false"),
    Mutant("pr_global_always", "PushRelabel.swift", "work > threshold", "true", nth=0),
    Mutant("pr_global_source", "PushRelabel.swift", "label[w] == n && w != source && residual[Int(mate[b])] > .zero", "label[w] == n && residual[Int(mate[b])] > .zero"),
    Mutant("pr_global_reverse", "PushRelabel.swift", "label[w] == n && w != source && residual[Int(mate[b])] > .zero", "label[w] == n && w != source && residual[b] > .zero", nth=0),
    Mutant("pr_global_active", "PushRelabel.swift", "excess[w] > .zero", "false", nth=0),
    Mutant("pr_global_current", "PushRelabel.swift", "current[w] = first[w]", "", mode="stmt", nth=0),

    # Push–relabel, phase 2
    Mutant("p2_source", "PushRelabel.swift", "marks[source] = true", "", mode="stmt"),
    Mutant("p2_reverse", "PushRelabel.swift", "!marks[w] && residual[Int(mate[b])] > .zero", "!marks[w] && residual[b] > .zero"),
    Mutant("p2_active", "PushRelabel.swift", "excess[w] > .zero", "false", nth=1),
    Mutant("p2_activate", "PushRelabel.swift", "w != source && excess[w] == .zero", "w != source"),
    Mutant("p2_amax", "PushRelabel.swift", "if below > aMax { aMax = below }", "", mode="stmt", nth=1),
    Mutant("p2_drop", "PushRelabel.swift", "lowest &+ 1 >= n", "true", nth=1),
    Mutant("p2_relabel", "PushRelabel.swift", "label[v] = dv", "", mode="stmt", nth=1),
    Mutant("p2_skip", "MaximumFlow.swift", "if algorithm == .pushRelabel { preflow.secondPhase(from: s, to: t) }", "", mode="stmt"),

    # The maximum-flow driver
    Mutant("mf_split_never", "MaximumFlow.swift", "_addingReportingOverflow(largest, largest).overflow", "false"),
    Mutant("mf_split_always", "MaximumFlow.swift", "_residualsMayOverflow(edges, capacities)", "!edges.directed", nth=1),
    Mutant("mf_split_net", "MaximumFlow.swift", "_residualsMayOverflow(edges, capacities) ? _splitUndirectedNetwork(edges, capacities, reusable: reusable) : _residualNetwork(edges, capacities, reusable: reusable)", "_residualNetwork(edges, capacities, reusable: reusable)"),
    Mutant("mf_ek_bound", "MaximumFlow.swift", "for a in network.first[s] ..< network.first[s + 1] { bound += network.residual[a] }", "", mode="stmt"),
    Mutant("mf_rowsum_eku", "MaximumFlow.swift", "network.checkRowSums([s])", "", mode="stmt", nth=0),
    Mutant("mf_rowsum", "MaximumFlow.swift", "network.checkRowSums([s])", "", mode="stmt", nth=1),
    Mutant("mf_backward", "MaximumFlow.swift", "network.directedFlow(2 * e + 1)", ".zero"),
    Mutant("mf_wantscut", "MaximumFlow.swift", "wantsCut || algorithm == .pushRelabel", "algorithm == .pushRelabel"),
    Mutant("mf_marksink", "MaximumFlow.swift", "_ = inSink.withUnsafeMutableBufferPointer { network.markSinkSide(t, $0.baseAddress!, queue) }", "", mode="stmt"),
    Mutant("mf_arcs", "MaximumFlow.swift", "flows.append(run.along[e])\n            flows.append(run.against[e])", "flows.append(run.against[e])\n            flows.append(run.along[e])", mode="stmt"),

    # Flow and Cut
    Mutant("fl_search", "Flow.swift", "positions[mid] < position", "positions[mid] <= position"),
    Mutant("fl_found", "Flow.swift", "low < positions.count && positions[low] == position", "low < positions.count"),
    Mutant("fl_map_order", "Flow.swift", "_graph.edges.index(after: i)", "_graph.edges.index(after: _graph.edges.index(after: i))"),
    Mutant("fl_signed", "Flow.swift", "flow(ofEdgeAt: .init(position: position, reversed: false)) - flow(ofEdgeAt: .init(position: position, reversed: true))", "flow(ofEdgeAt: .init(position: position, reversed: true)) - flow(ofEdgeAt: .init(position: position, reversed: false))"),
    Mutant("fl_equal", "Flow.swift", "lhs.value == rhs.value && lhs._flows == rhs._flows", "lhs.value == rhs.value"),
    Mutant("cut_back", "Cut.swift", "!inSink[u] && inSink[v]", "inSink[u] != inSink[v]"),
    Mutant("cut_value", "Cut.swift", "value += capacities[e]", "", mode="stmt", nth=0),
    Mutant("cut_reversed", "Cut.swift", "inSink[u]", "inSink[v]", nth=3),
    Mutant("cut_equal", "Cut.swift", "lhs.value == rhs.value && lhs.sourceSide == rhs.sourceSide && lhs.sinkSide == rhs.sinkSide && lhs.edges == rhs.edges", "lhs.value == rhs.value"),

    # Stoer–Wagner
    Mutant("gc_positive", "GlobalMinimumCut.swift", "capacities[e] > .zero", "true", nth=0),
    Mutant("gc_union", "GlobalMinimumCut.swift", "if a != b { parent[a] = b }", "", mode="stmt"),
    Mutant("gc_component_side", "GlobalMinimumCut.swift", "inSink[v] = _unionFindRoot(v, &parent) != firstRoot", "inSink[v] = _unionFindRoot(v, &parent) == firstRoot", mode="stmt"),
    Mutant("ni_merge_parallel", "GlobalMinimumCut.swift", "capacity[mark[v]] += c", "", mode="stmt"),
    Mutant("ni_contract_all", "GlobalMinimumCut.swift", "!(scanned[e] < best)", "true"),
    Mutant("ni_prefix", "GlobalMinimumCut.swift", "prefix = (prefix + sum[x]) - (connection + connection)", "prefix = prefix + sum[x]", mode="stmt"),
    Mutant("ni_phase_last", "GlobalMinimumCut.swift", "!heap.isEmpty && (phaseBest == nil || prefix < phaseBest!)", "(phaseBest == nil || prefix < phaseBest!)"),
    Mutant("ni_scanned", "GlobalMinimumCut.swift", "if let key = heap.raise(t, by: capacity[a >> 1]) { scanned[a >> 1] = key }", "_ = heap.raise(t, by: capacity[a >> 1])", mode="stmt"),
    Mutant("ni_parallel_q", "GlobalMinimumCut.swift", "if scanned[c >> 1] < scanned[b >> 1] { scanned[c >> 1] = scanned[b >> 1] }", "", mode="stmt"),
    Mutant("ni_sum_merge", "GlobalMinimumCut.swift", "sum[x] += capacity[b >> 1]", "", mode="stmt", nth=0),
    Mutant("ni_sum_drop", "GlobalMinimumCut.swift", "sum[x] -= capacity[e]", "", mode="stmt"),
    Mutant("ni_members", "GlobalMinimumCut.swift", "nextMember[lastMember[x]] = y", "", mode="stmt"),
    Mutant("ni_flip", "GlobalMinimumCut.swift", "inSink[v] = inBest[v] != flip", "inSink[v] = inBest[v]", mode="stmt"),
    Mutant("ni_buckets_off", "GlobalMinimumCut.swift", "integerKeys && largest <= 4 * (alive + slots)", "false"),
    Mutant("ni_buckets_top", "GlobalMinimumCut.swift", "if k > top { top = k }", "", mode="stmt"),
    Mutant("ni_buckets_unlink", "GlobalMinimumCut.swift", "if q >= 0 { previous[q] = p }", "", mode="stmt"),
    Mutant("hp_up", "GlobalMinimumCut.swift", "guard k > key[above] else { break }", "break", mode="stmt"),
    Mutant("hp_down", "GlobalMinimumCut.swift", "guard bestKey > k else { break }", "break", mode="stmt"),
    Mutant("hp_child", "GlobalMinimumCut.swift", "ck > bestKey", "false"),
    Mutant("hp_arity", "GlobalMinimumCut.swift", "Swift.min(firstChild &+ 4, count)", "Swift.min(firstChild &+ 3, count)"),

    # The directed global cut
    Mutant("ho_reverse_pass", "HaoOrlin.swift", "_haoOrlinPass(reversed, &best, &inSink, sinkIsAwake: false)", "", mode="stmt"),
    Mutant("ho_side", "HaoOrlin.swift", "inSink[v] = sinkIsAwake", "inSink[v] = !sinkIsAwake", mode="stmt"),
    Mutant("ho_gap", "HaoOrlin.swift", "next[x] < 0", "false"),
    Mutant("ho_sleep_alone", "HaoOrlin.swift", "nextBucket == Int.max", "false"),
    Mutant("ho_wake", "HaoOrlin.swift", "buckets.dormant[c] = false", "", mode="stmt"),
    Mutant("ho_first_least", "HaoOrlin.swift", "excess[target] < best!", "excess[target] <= best!"),
    Mutant("ho_dormant_skip", "HaoOrlin.swift", "buckets.dormant[bv]", "false"),
    Mutant("wd_int_always", "WideCapacities.swift", "fits && total <= Int.max / 2", "true"),
    Mutant("wd_float", "WideCapacities.swift", "return algorithm.run((capacities as! [Float]).map { Double($0) }) { Float($0) as! A.Capacity }", "return algorithm.run(capacities) { $0 }", mode="stmt"),

    # Gomory–Hu (Gusfield)
    Mutant("gh_reset", "GomoryHuTree.swift", "if s > 1 { network.reset() }", "", mode="stmt"),
    Mutant("gh_split", "GomoryHuTree.swift", "_flowNetwork(edges, wide, reusable: true)", "_residualNetwork(edges, wide, reusable: true)"),
    Mutant("gh_reparent_self", "GomoryHuTree.swift", "i != s && !sinkSide[i] && parent[i] == t", "!sinkSide[i] && parent[i] == t"),
    Mutant("gh_reparent_parent", "GomoryHuTree.swift", "i != s && !sinkSide[i] && parent[i] == t", "i != s && !sinkSide[i]", nth=0),
    Mutant("gh_swap", "GomoryHuTree.swift", "t != 0 && !sinkSide[parent[t]]", "false"),
    Mutant("gh_swap_value", "GomoryHuTree.swift", "value[s] = value[t]", "", mode="stmt"),
    Mutant("gh_depth", "GomoryHuTree.swift", "_depth[a] > _depth[b]", "false"),
    Mutant("gh_least", "GomoryHuTree.swift", "_capacity[x] < least", "_capacity[x] > least"),
    Mutant("gh_nearest", "GomoryHuTree.swift", "_capacity[x] < _capacity[chosen]", "_capacity[x] <= _capacity[chosen]"),
    Mutant("gh_subtree", "GomoryHuTree.swift", "below[children[k]] = true", "", mode="stmt"),
    Mutant("gh_side", "GomoryHuTree.swift", "below.map { $0 != uBelow }", "below"),
    Mutant("gh_position", "GomoryHuTree.swift", "position >= 0 && position < _capacity.count - 1", "position < _capacity.count - 1"),
    Mutant("gh_equal", "GomoryHuTree.swift", "lhs._capacity.dropFirst() == rhs._capacity.dropFirst()", "true"),

    # Network simplex: start, pivot rule, leaving arc, flow change
    Mutant("ns_potential_start", "NetworkSimplex.swift", "potential[u] = artificialCost", "potential[u] = 0", mode="stmt"),
    Mutant("ns_artificial_up", "NetworkSimplex.swift", "cost[e] = 0", "cost[e] = artificialCost", mode="stmt"),
    Mutant("ns_mixing", "NetworkSimplex.swift", "i = j", "i = j + 1", mode="stmt"),
    Mutant("ns_mixing_off", "NetworkSimplex.swift", "max(m / n, 3)", "1"),
    Mutant("ns_feasible", "NetworkSimplex.swift", "for e in arcCount ..< allArcCount where flow[e] != 0 { return false }", "", mode="stmt"),
    Mutant("ns_initial", "NetworkSimplex.swift", "initialPivots(supply, &pivot)", "", mode="stmt"),
    Mutant("ns_initial_capacity", "NetworkSimplex.swift", "capacity[e] >= total", "true"),
    Mutant("ns_block_last", "NetworkSimplex.swift", "guard best < 0 else { return false }", "return false", mode="stmt"),
    Mutant("ns_join", "NetworkSimplex.swift", "successorCount[u] < successorCount[v]", "successorCount[u] > successorCount[v]"),
    Mutant("ns_leave_first", "NetworkSimplex.swift", "d < delta", "d <= delta"),
    Mutant("ns_leave_second", "NetworkSimplex.swift", "d <= delta", "d < delta", nth=1),
    Mutant("ns_leave_direction", "NetworkSimplex.swift", "predDirection[u] == Self.down", "predDirection[u] == Self.up"),
    Mutant("ns_leave_side", "NetworkSimplex.swift", "result == 1", "result == 2"),
    Mutant("ns_infinite_max", "NetworkSimplex.swift", "d = capacity[e] &- d", "d = capacity[e] == Int.max ? Int.max : capacity[e] &- d", mode="stmt", nth=0),
    Mutant("ns_artificial_blocks", "NetworkSimplex.swift", "e >= arcCount", "false", nth=1),
    Mutant("ns_change_sign", "NetworkSimplex.swift", "flow[pred[u]] &-= predDirection[u] &* value", "flow[pred[u]] &+= predDirection[u] &* value", mode="stmt"),
    Mutant("ns_change_state", "NetworkSimplex.swift", "flow[pred[pivot.uOut]] == 0 ? Self.lower : Self.upper", "Self.lower"),
    Mutant("ns_flip", "NetworkSimplex.swift", "state[inArc] = -state[inArc]", "", mode="stmt"),

    # Network simplex: the tree update and potentials
    Mutant("ut_parent_simple", "NetworkSimplex.swift", "parent[uIn] = vIn", "", mode="stmt"),
    Mutant("ut_direction_simple", "NetworkSimplex.swift", "uIn == Int(source[inArc]) ? Self.up : Self.down", "Self.up", nth=0),
    Mutant("ut_direction_stem", "NetworkSimplex.swift", "uIn == Int(source[inArc]) ? Self.up : Self.down", "Self.down", nth=1),
    Mutant("ut_thread_simple", "NetworkSimplex.swift", "thread[vIn] != uOut", "true"),
    Mutant("ut_continue", "NetworkSimplex.swift", "oldReverseThread == vIn ? thread[oldLastSuccessor] : thread[vIn]", "thread[vIn]"),
    Mutant("ut_stem_last", "NetworkSimplex.swift", "lastSuccessor[stem] == lastSuccessor[parentStem] ? reverseThread[parentStem] : lastSuccessor[stem]", "lastSuccessor[stem]"),
    Mutant("ut_parent_out", "NetworkSimplex.swift", "parent[uOut] = parentStem", "", mode="stmt"),
    Mutant("ut_old_reverse", "NetworkSimplex.swift", "oldReverseThread != vIn", "true"),
    Mutant("ut_dirty", "NetworkSimplex.swift", "reverseThread[thread[u]] = u", "", mode="stmt"),
    Mutant("ut_pred_direction", "NetworkSimplex.swift", "predDirection[u] = -predDirection[p]", "predDirection[u] = predDirection[p]", mode="stmt"),
    Mutant("ut_size_stem", "NetworkSimplex.swift", "sizeSum &+= successorCount[u] &- successorCount[p]", "sizeSum &+= successorCount[u]", mode="stmt"),
    Mutant("ut_last_stem", "NetworkSimplex.swift", "lastSuccessor[p] = lastOfOut", "", mode="stmt"),
    Mutant("ut_size_in", "NetworkSimplex.swift", "successorCount[uIn] = oldSuccessorCount", "", mode="stmt"),
    Mutant("ut_last_vin", "NetworkSimplex.swift", "lastSuccessor[u] = lastSuccessorOut", "", mode="stmt", nth=0),
    Mutant("ut_vout_cond", "NetworkSimplex.swift", "join != oldReverseThread && vIn != oldReverseThread", "join != oldReverseThread"),
    Mutant("ut_vout_limit", "NetworkSimplex.swift", "u != upLimitOut && lastSuccessor[u] == oldLastSuccessor", "u != -1 && lastSuccessor[u] == oldLastSuccessor", nth=0),
    Mutant("ut_vout_reverse", "NetworkSimplex.swift", "lastSuccessor[u] = oldReverseThread", "", mode="stmt"),
    Mutant("ut_vout_else", "NetworkSimplex.swift", "lastSuccessorOut != oldLastSuccessor", "false"),
    Mutant("ut_size_vin", "NetworkSimplex.swift", "successorCount[u] &+= oldSuccessorCount", "", mode="stmt"),
    Mutant("ut_size_vout", "NetworkSimplex.swift", "successorCount[u] &-= oldSuccessorCount", "", mode="stmt"),
    Mutant("ns_sigma", "NetworkSimplex.swift", "potential[pivot.vIn] &- potential[uIn] &- predDirection[uIn] &* cost[pivot.inArc]", "potential[pivot.vIn] &- potential[uIn] &+ predDirection[uIn] &* cost[pivot.inArc]"),
    Mutant("ns_subtree", "NetworkSimplex.swift", "thread[lastSuccessor[uIn]]", "thread[uIn]"),

    # Minimum-cost flow
    Mutant("mcf_balance", "MinimumCostFlow.swift", "guard total == 0 else { return nil }", "", mode="stmt"),
    Mutant("mcf_loop", "MinimumCostFlow.swift", "if cost[e] < 0 { flows[e] = capacity[e] }", "", mode="stmt"),
    Mutant("mcf_loop_zero", "MinimumCostFlow.swift", "cost[e] < 0", "cost[e] <= 0"),
    Mutant("mcf_greatest", "MinimumCostFlow.swift", "greatest = max(greatest, cost[e].magnitude > UInt(Int.max) ? Int.max : abs(cost[e]))", "", mode="stmt"),
    Mutant("mcf_bigm", "MinimumCostFlow.swift", "(greatest &+ 1).multipliedReportingOverflow(by: n &+ 1)", "(greatest &+ 1).multipliedReportingOverflow(by: 1)"),
    Mutant("mcf_room", "MinimumCostFlow.swift", "!overflowM && !overflowRoom", "!overflowM"),
    Mutant("mcf_potentials", "MinimumCostFlow.swift", "for v in 0 ..< n { potentials[v] = simplex.potential[v] }", "", mode="stmt"),
    Mutant("mcf_total", "MinimumCostFlow.swift", "totalCost += flows[e] * cost[e]", "", mode="stmt"),
    Mutant("mcf_shipped", "MinimumCostFlow.swift", "b > 0", "b != 0"),
    Mutant("mcf_capacity_sign", "MinimumCostFlow.swift", "precondition(c >= 0, \"A capacity is negative\")", "", mode="stmt"),
    Mutant("mcf_cost_bound", "MinimumCostFlow.swift", "!o1 && !o2 && W(exactly: sum) != nil", "!o1 && !o2"),
    Mutant("mcf_map", "MinimumCostFlow.swift", "FlowMap(graph: _graph, positions: _positions, flows: _flows)", "FlowMap(graph: _graph, positions: _positions, flows: _flows.reversed())"),
    Mutant("mcf_equal", "MinimumCostFlow.swift", "lhs._flows == rhs._flows && lhs._potentials == rhs._potentials", "lhs._flows == rhs._flows"),
    Mutant("mcmf_demand", "MinimumCostFlow.swift", "supplies[t] = -value", "", mode="stmt"),

    # Connectivity
    Mutant("cn_split_unit", "Connectivity.swift", "capacity.append(1)", "capacity.append(n)", mode="stmt"),
    Mutant("cn_drop", "Connectivity.swift", "u == dropFrom && v == dropTo ? 0 : n", "n"),
    Mutant("cn_drop_reverse", "Connectivity.swift", "v == dropFrom && u == dropTo ? 0 : n", "n"),
    Mutant("cn_split_both", "Connectivity.swift", "!edges.directed", "false", nth=0),
    Mutant("cn_adjacent", "Connectivity.swift", "(u == s && v == t) || (!edges.directed && u == t && v == s)", "(u == s && v == t)"),
    Mutant("cn_adjacent_path", "Connectivity.swift", "if adjacent { return (value + 1, nil) }", "if adjacent { return (value, nil) }", mode="stmt"),
    Mutant("cn_splitcut", "Connectivity.swift", "!marks[2 * v] && marks[2 * v + 1]", "marks[2 * v + 1]"),
    Mutant("ev_bound", "Connectivity.swift", "i < n && i <= best", "i < n && i < best"),
    Mutant("ev_successor", "Connectivity.swift", "if u == i { successor[v] = true }", "", mode="stmt"),
    Mutant("ev_undirected", "Connectivity.swift", "!edges.directed", "false", nth=2),
    Mutant("ev_directions", "Connectivity.swift", "edges.directed ? 2 : 1", "1"),
    Mutant("ev_reset", "Connectivity.swift", "if used { network.reset() }", "", mode="stmt"),
    Mutant("ev_strict", "Connectivity.swift", "value < best", "value <= best", nth=0),
    Mutant("ev_cutoff", "Connectivity.swift", "_dinic(network, from: 2 * a + 1, to: 2 * b, cutoff: best)", "_dinic(network, from: 2 * a + 1, to: 2 * b)"),
    Mutant("ec_crossing", "Connectivity.swift", "inSink[Int(edges.tail[e])] != inSink[Int(edges.head[e])]", "!inSink[Int(edges.tail[e])] && inSink[Int(edges.head[e])]"),

    # Disjoint paths
    Mutant("dp_cycle_marks", "DisjointPaths.swift", "for y in vertices[(k + 1)...] { onWalk[y] = -1 }", "", mode="stmt"),
    Mutant("dp_cycle_off", "DisjointPaths.swift", "k >= 0", "false"),
    Mutant("dp_back", "DisjointPaths.swift", "if back > 0 { arcs[v].append((u, e, true)) }", "", mode="stmt"),
    Mutant("dp_direct", "DisjointPaths.swift", "paths.append(([s, t], [(e, false)]))", "", mode="stmt"),
    Mutant("dp_direct_reversed", "DisjointPaths.swift", "paths.append(([s, t], [(e, true)]))", "paths.append(([s, t], [(e, false)]))", mode="stmt"),
    Mutant("dp_drop", "DisjointPaths.swift", "capacity.append(u == s && v == t ? 0 : n)", "capacity.append(n)", mode="stmt"),
    Mutant("dp_split_unit", "DisjointPaths.swift", "capacity.append(1)", "capacity.append(n)", mode="stmt"),

    # Reading the graph and the capacities
    Mutant("fe_nan", "FlowEdges.swift", "precondition(c == c, \"A capacity is NaN\")", "", mode="stmt"),
    Mutant("fe_negative", "FlowEdges.swift", "precondition(c >= .zero, \"A capacity is negative\")", "", mode="stmt"),
    Mutant("fe_infinite", "FlowEdges.swift", "precondition(c - c == .zero, \"A capacity is infinite\")", "", mode="stmt"),
    Mutant("fe_loops_asked", "FlowEdges.swift", "edges.tail[e] != edges.head[e]", "true"),
    Mutant("fe_orient", "FlowEdges.swift", "tail[e] != head[e] && edges[position].u != _vertex(number: Int(tail[e]), listed)", "false"),
    Mutant("fe_contains_directed", "FlowEdges.swift", "precondition(contains(vertex), \"\\(vertex) is not a vertex of the graph\")", "", mode="stmt", nth=0),
    Mutant("fe_contains_undirected", "FlowEdges.swift", "precondition(contains(vertex), \"\\(vertex) is not a vertex of the graph\")", "", mode="stmt", nth=1),
    Mutant("fe_float_overflow", "FlowEdges.swift", "sum - sum != .zero", "false"),
]
