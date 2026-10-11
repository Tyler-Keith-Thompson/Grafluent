# Planted bugs for DirectedAcyclicGraphModule and the MutableDirectedGraph hooks it reads in
# AdjacencyListModule, Multigraphs and StableGraphs (module=...); run with
# `just mutate DirectedAcyclicGraphModule`. See scripts/mutate.py. The hooks' mutants run
# DirectedAcyclicGraphTests first, then the bases' own suites.
#
# Known equivalent mutants (they survive by design):
#   forwardbound      the forward search without its bound (label < upper): a vertex it then
#                     reaches placed after the source is not an ancestor of the source, so it is
#                     never in the backward set, and the merge hands it back its own label (the
#                     |B| + |F before u| smallest labels are exactly the old ones of those
#                     vertices). Same order; it only visits more. Time only: see
#                     Benchmarks (DirectedAcyclicGraph insertion), where the bound is the
#                     difference between O(δ) and O(n) per backward edge.
#   backwardbound     the backward search without its bound (label > lower): the mirror image.
#   sharedmark        the backward search marking with the forward search's stamp: the two sets
#                     are disjoint (a vertex in both would make the target reach the source), so
#                     no vertex the backward search needs carries the forward mark.
#   placesfresh       always building the compacted places: the same places. Time only.
#   compactnever      never compacting: holes and free front slots only cost memory and the
#   compactalways     Fenwick count; compacting after every removal gives the same order. Time
#                     and memory only (amortized O(1) per removal against O(n)).
#   holerankbuild     rebuilding the Fenwick tree for every hole: the same tree. Time only.
#   flatread          never reading a label directly at the key: the page table gives the same
#                     entry. Time only.
#   sortsmallonly     one sort for every size: both sort by distinct labels, so the same
#   sortlargeonly     order. Time only.
#   selectfast        the Fenwick descent without holes: the same slot. Time only.
#   hasPathrevisit    hasPath(from:to:) without its visited bits: the same answer on a DAG, in
#                     exponential time in the worst case.
#   reachfirstword    starting the row union at word 0 instead of the successor's word: the
#                     skipped words of a later row are zero. Time only.
#   insertmark        not clearing a new key's visit mark: marks are stamps that only grow, so a
#                     stale mark (from a freed block) is never the current search's.

TESTS = ["DirectedAcyclicGraphTests", "AdjacencyListTests", "MultigraphsTests", "StableGraphsTests"]

K = "DirectedAcyclicGraph.swift"
M = "DirectedAcyclicGraph+Mutation.swift"
A = "DirectedAcyclicGraph+Algorithms.swift"
B = "DirectedAcyclicGraph+Construction.swift"
C = "DirectedAcyclicGraph+Conformances.swift"
D = "DirectedAcyclicGraph+DirectedGraph.swift"

AL = "AdjacencyList.swift"
PS = "DirectedPseudograph.swift"
ST = "StableDirectedGraph+Conformances.swift"

MUTANTS = [
    # The places: the slots and labels themselves without holes, or a compacted copy.
    Mutant("placesstale", K, "        if _order.holes == 0 { return _Places(keys: _order.slots, start: _order.first, table: _table) }", "        return _Places(keys: _order.slots, start: _order.first, table: _table)", mode="stmt"),
    Mutant("placesfresh", K, "        if _order.holes == 0 { return _Places(keys: _order.slots, start: _order.first, table: _table) }", "", mode="stmt"),
    Mutant("placesstart", K, "        if _order.holes == 0 { return _Places(keys: _order.slots, start: _order.first, table: _table) }", "        if _order.holes == 0 { return _Places(keys: _order.slots, start: 0, table: _table) }", mode="stmt"),
    Mutant("placescopylabel", K, "for (place, key) in keys.enumerated() { table.setLabel(key, place) }", "for (place, key) in keys.enumerated() { table.setLabel(key, place &+ 1) }", mode="stmt"),

    # Compaction and the free front slots.
    Mutant("compactlabel", K, "                _table.setLabel(key, write)", "", mode="stmt"),
    Mutant("compactfirst", K, "        _order.first = 0\n        _order.holes = 0\n        _order.rank = []", "        _order.holes = 0\n        _order.rank = []", mode="stmt"),
    Mutant("compactrank", K, "        _order.first = 0\n        _order.holes = 0\n        _order.rank = []", "        _order.first = 0\n        _order.holes = 0", mode="stmt"),
    Mutant("growrelabel", K, "            if key >= 0 { _table.setLabel(key, slot &+ extra) }", "", mode="stmt"),
    Mutant("growfirst", K, "_order.first &+= extra", "_order.first &+= extra &- 1"),
    Mutant("growrank", K, "        if _order.holes > 0 { _order.buildRank() } else { _order.rank = [] }", "        _order.rank = []", mode="stmt"),

    # Places and slots through the Fenwick tree.
    Mutant("placenoholes", K, "slot &- first &- holesBefore(slot)", "slot &- first"),
    Mutant("holesbeforestep", K, "            j &= j &- 1", "            j &-= 1", mode="stmt"),
    Mutant("selectfirst", K, "first &+ place &+ 1", "place &+ 1"),
    Mutant("selectstep", K, "open < remaining", "open <= remaining"),
    Mutant("selectfast", K, "if holes == 0 { return first &+ place }", "", mode="stmt"),
    Mutant("addholesstep", K, "            j &+= j & (0 &- j)", "            j &+= 1", mode="stmt"),
    Mutant("buildparent", K, "            if parent <= size { rank[parent &- 1] &+= rank[j &- 1] }", "", mode="stmt"),
    Mutant("buildleaf", K, "            if slots[slot] < 0 { rank[slot] = 1 }", "", mode="stmt"),
    Mutant("trimlastrank", K, "                addHoles(-1, at: slots.count &- 1)", "", mode="stmt"),
    Mutant("trimlastcount", K, "                holes &-= 1\n                slots.removeLast()", "                slots.removeLast()", mode="stmt"),
    Mutant("trimfirstrank", K, "                addHoles(-1, at: first)", "", mode="stmt"),
    Mutant("trimfirst", K, "slot == first", "false"),
    Mutant("trimlast", K, "slot == slots.count &- 1", "false"),
    Mutant("holecount", K, "            holes &+= 1", "", mode="stmt"),
    Mutant("holerankbuild", K, "if slot < rank.count { addHoles(1, at: slot) } else { buildRank() }", "buildRank()", mode="stmt"),
    Mutant("holerankadd", K, "if slot < rank.count { addHoles(1, at: slot) } else { buildRank() }", "addHoles(1, at: slot)", mode="stmt"),

    # The paged table.
    Mutant("slotoffset", K, "pages[(key &>> _PositionPage.shift) &- firstPage] &<< _PositionPage.shift | (key & _PositionPage.mask)", "pages[(key &>> _PositionPage.shift) &- firstPage] &<< _PositionPage.shift"),
    Mutant("slotfirstpage", K, "(key &>> _PositionPage.shift) &- firstPage", "key &>> _PositionPage.shift", nth=2),
    Mutant("flatread", K, "        if flat { return key }", "", mode="stmt"),
    Mutant("flatkept", K, "            if block != page || firstPage != 0 { flat = false }", "", mode="stmt"),
    Mutant("pagegrow", K, "k >= pages.count", "k > pages.count"),
    Mutant("pageprepend", K, "pages.insert(contentsOf: repeatElement(-1, count: firstPage &- start), at: 0)", "pages.insert(contentsOf: repeatElement(-1, count: firstPage &- start &- 1), at: 0)", mode="stmt"),
    Mutant("blockreuse", K, "free.popLast()", "free.last"),
    Mutant("blocklive", K, "        live[block] &+= 1", "        live[block] &+= 2", mode="stmt"),
    Mutant("blockfreeearly", K, "guard live[block] == 0 else { return }", "guard live[block] <= 1 else { return }", mode="stmt"),
    Mutant("blockunlink", K, "        pages[k] = -1\n        free.append(block)", "        free.append(block)", mode="stmt"),
    Mutant("fronttrim", K, "            firstPage &+= front\n            front = 0", "            front = 0", mode="stmt"),
    Mutant("insertlabel", K, "        labels[slot] = label", "", mode="stmt"),
    Mutant("insertmark", K, "        marks[slot] = 0", "", mode="stmt"),
    Mutant("tableclear", K, "        pages.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),

    # Vertex insertion.
    Mutant("insertexisting", M, "return (false, _base._vertex(atKey: key))", "return (true, vertex)", mode="stmt"),
    Mutant("appendlabel", M, "_table.insert(key, label: _order.slots.count)", "_table.insert(key, label: _order.slots.count &+ 1)"),
    Mutant("appendorder", M, "        _order.slots.append(key)", "", mode="stmt"),
    Mutant("prependlast", M, "return _insertEdge(_prependVertex(edge.source), target)", "return _insertEdge(_appendVertex(edge.source), target)", mode="stmt"),
    Mutant("prependgrow", M, "        if _order.first == 0 { _growFront() }", "", mode="stmt"),
    Mutant("prependlabel", M, "_table.insert(key, label: _order.first)", "_table.insert(key, label: _order.first &+ 1)"),

    # Edge insertion.
    Mutant("selfloop", M, "if edge.source == edge.target { return nil }", "", mode="stmt"),
    Mutant("safeselfloop", M, "source != target", "true"),
    Mutant("safemissingsource", M, "_base._key(of: edge.source)", "Optional(_base._key(of: edge.source) ?? 0)", nth=1),
    Mutant("safemissingtarget", M, "_base._key(of: edge.target)", "Optional(_base._key(of: edge.target) ?? 0)", nth=2),
    Mutant("forwardtest", M, "_table.label(source) > _table.label(target)", "_table.label(source) < _table.label(target)"),
    Mutant("forwardskip", M, "_table.label(source) > _table.label(target)", "false"),
    Mutant("rejectignored", M, "guard _reorder(source: source, target: target) else { return nil }", "_ = _reorder(source: source, target: target)", mode="stmt"),

    # Pearce–Kelly: the forward search.
    Mutant("stamp", M, "        _stamp &+= 2", "", mode="stmt"),
    Mutant("sharedmark", M, "_stamp &+ 1", "_stamp"),
    Mutant("cycle", M, "                if next == source { return false }", "", mode="stmt"),
    Mutant("forwardbound", M, "label < upper", "true"),
    Mutant("forwardrevisit", M, "_table.marks[slot] != forwardMark", "true"),
    Mutant("forwardmark", M, "                    _table.marks[slot] = forwardMark", "", mode="stmt"),
    Mutant("forwardseed", M, "        _forward.append(_Placed(label: lower, key: target))", "", mode="stmt"),
    Mutant("forwardscratch", M, "        _forward.removeAll(keepingCapacity: true)", "", mode="stmt"),

    # Pearce–Kelly: the backward search.
    Mutant("backwardbound", M, "label > lower", "true"),
    Mutant("backwardrevisit", M, "_table.marks[slot] != backwardMark", "true"),
    Mutant("backwardseed", M, "        _backward.append(_Placed(label: upper, key: source))", "", mode="stmt"),
    Mutant("backwardscratch", M, "        _backward.removeAll(keepingCapacity: true)", "", mode="stmt"),
    Mutant("backwardpredecessors", M, "_base._predecessorKeys(ofKey: key)", "_base._predecessorKeys(ofKey: source)"),

    # Pearce–Kelly: reordering and slot assignment.
    Mutant("sortforward", M, "        Self._sortByLabel(&_forward)", "", mode="stmt"),
    Mutant("sortbackward", M, "        Self._sortByLabel(&_backward)", "", mode="stmt"),
    Mutant("sortsmallonly", M, "placed.count > 24", "false"),
    Mutant("sortlargeonly", M, "placed.count > 24", "true"),
    Mutant("insertionsortshift", M, "                    placed[j] = placed[j &- 1]", "", mode="stmt"),
    Mutant("insertionsortorder", M, "placed[j &- 1].label > moving.label", "placed[j &- 1].label < moving.label"),
    Mutant("mergeend", M, "b == _backward.count || (f < _forward.count && _forward[f].label < _backward[b].label)", "f < _forward.count && _forward[f].label < _backward[b].label"),
    Mutant("mergeorder", M, "_forward[f].label < _backward[b].label", "_forward[f].label > _backward[b].label", nth=1),
    Mutant("labelsscratch", M, "        _labels.removeAll(keepingCapacity: true)", "", mode="stmt"),
    Mutant("backwardlabel", M, "_table.setLabel(moved.key, _labels[i])", "_table.setLabel(moved.key, moved.label)", nth=0),
    Mutant("forwardlabel", M, "_table.setLabel(moved.key, _labels[i])", "_table.setLabel(moved.key, moved.label)", nth=1),
    Mutant("backwardplace", M, "            _order.slots[_labels[i]] = moved.key", "", mode="stmt", nth=0),
    Mutant("forwardplace", M, "            _order.slots[_labels[i]] = moved.key", "", mode="stmt", nth=1),

    # Removal: the hole, and re-keying the base's swap-removed vertex.
    Mutant("removeorder", M, "        _order.remove(at: slot)", "", mode="stmt"),
    Mutant("removetable", M, "            _table.remove(key)", "", mode="stmt"),
    Mutant("movedlabel", M, "            _table.setLabel(key, movedSlot)", "", mode="stmt"),
    Mutant("movedplace", M, "            _order.slots[movedSlot] = key", "", mode="stmt"),
    Mutant("movedunlink", M, "            _table.remove(moved)", "", mode="stmt"),
    Mutant("compactnever", M, "(_order.holes > 0 && _order.holes >= live) || _order.first > live &* 2 &+ 16", "false"),
    Mutant("compactalways", M, "(_order.holes > 0 && _order.holes >= live) || _order.first > live &* 2 &+ 16", "true"),
    Mutant("removeresult", M, "return removed", "return _base._vertex(atKey: key)", mode="stmt"),
    Mutant("removeallorder", M, "        _order.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("removealltable", M, "        _table.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),

    # hasPath(from:to:), pruned by the order.
    Mutant("hasPathsame", A, "if start == goal { return true }", "", mode="stmt"),
    Mutant("hasPathbackward", A, "if lower > upper { return false }", "", mode="stmt"),
    Mutant("hasPathgoal", A, "if next == goal { return true }", "", mode="stmt"),
    Mutant("hasPathbound", A, "label < upper", "label <= upper"),
    Mutant("hasPathrevisit", A, "seen[word] & mask == 0", "true"),
    Mutant("hasPathmark", A, "                        seen[word] |= mask", "", mode="stmt"),
    Mutant("hasPathbit", A, "UInt64(1) &<< UInt64(bit & 63)", "UInt64(1) &<< UInt64(bit & 31)"),

    # Reachability bit rows.
    Mutant("reachdirect", A, "                    rows[row &+ q &>> 6] |= UInt64(1) &<< UInt64(q & 63)", "", mode="stmt"),
    Mutant("reachunion", A, "                        rows[row &+ w] |= rows[other &+ w]", "", mode="stmt"),
    Mutant("reachfirstword", A, "q &>> 6", "0", nth=1),
    Mutant("reachskipword", A, "q &>> 6", "(q &>> 6) &+ 1", nth=1),

    # Transitive closure.
    Mutant("closureplaces", A, "places.place(ofKey: next)", "_table.label(next)", nth=1),
    Mutant("closurehave", A, "                have[q &>> 6] |= UInt64(1) &<< UInt64(q & 63)", "", mode="stmt"),
    Mutant("closureclear", A, "                have[w] = 0", "", mode="stmt"),
    Mutant("closurenext", A, "missing &= missing &- 1", "missing &= missing &>> 1"),

    # Transitive reduction.
    Mutant("reductionplaces", A, "places.place(ofKey: next)", "_table.label(next)", nth=2),
    Mutant("reductionfar", A, "for w in 0 ..< words { far[w] |= rows[other &+ w] }", "", mode="stmt"),
    Mutant("reductionfarclear", A, "                    far[w] = 0", "", mode="stmt"),
    Mutant("reductionskip", A, "if rows[at] & mask != 0 { continue }", "", mode="stmt"),
    Mutant("reductionfirstcopy", A, "            rows[at] |= mask", "", mode="stmt"),
    Mutant("reductionorder", A, "table.setLabel(new, place)", "table.setLabel(new, new)"),

    # Longest path.
    Mutant("longestempty", A, "guard n > 0 else { return nil }", "", mode="stmt"),
    Mutant("longestplaces", A, "places.place(ofKey: previous)", "_table.label(previous)"),
    Mutant("longestfirstedge", A, "candidate > d", "candidate >= d"),
    Mutant("longestrestart", A, "d >= .zero", "d > .zero"),
    Mutant("longestnegative", A, "d >= .zero", "true"),
    Mutant("longestfirstend", A, "if distance[p] > distance[best] { best = p }", "if distance[p] >= distance[best] { best = p }", mode="stmt"),
    Mutant("longestunit", A, "_longestPath { _ in 1 }", "_longestPath { _ in 2 }"),

    # Construction: Kahn's algorithm.
    Mutant("kahndecrement", B, "                table.setLabel(target, remaining)", "", mode="stmt"),
    Mutant("kahncycle", B, "        guard order.count == base.vertexCount else { return nil }", "", mode="stmt"),
    Mutant("kahnplaces", B, "        for (place, key) in order.enumerated() { table.setLabel(key, place) }", "", mode="stmt"),
    Mutant("kahnlifo", B, "order[next]", "order[order.count &- 1 &- next]"),
    Mutant("buildrepeat", B, "for vertex in vertices where base._key(of: vertex) == nil { _ = base._insertVertex(vertex) }", "for vertex in vertices { _ = base.insert(vertex) }", mode="stmt"),
    Mutant("convertsame", B, "graph as? Self", "Optional<Self>.none"),
    Mutant("convertbase", B, "graph as? Base", "Optional<Base>.none"),

    # Codable re-checks.
    Mutant("encodeoffsets", C, "offsets.insert(key, label: offset)", "offsets.insert(key, label: key)"),
    Mutant("decodecycle", C, "DirectedAcyclicGraph(base) != nil", "true"),
    Mutant("decodecount", C, "offsets.count == keys.count", "true"),
    Mutant("decodenegative", C, "offset >= 0", "true"),
    Mutant("decodehigh", C, "offset < keys.count", "true"),
    Mutant("decoderepeat", C, "table.label(keys[offset]) < 0", "true"),
    Mutant("decodeplaced", C, "            table.setLabel(keys[offset], place)", "", mode="stmt"),
    Mutant("encodeholes", C, "key >= 0", "key != -2"),
    Mutant("decodebackward", C, "table.label(base._sourceKey(ofEdgeAt: position)) >= table.label(base._targetKey(ofEdgeAt: position))", "false"),
    Mutant("equality", C, "lhs._base == rhs._base", "true"),
    Mutant("hashing", C, "_base.hash(into: &hasher)", "()"),

    # The order view and safe: lookups.
    Mutant("positionsafe", D, "_base._key(of: vertex).map { _position(ofKey: $0) }", "Optional(0)"),
    Mutant("orderfirstindex", D, "base._key(of: element).map { order.place(ofSlot: table.label($0)) }", "base._key(of: element).map { _ in 0 }"),
    Mutant("ordersubscriptcheck", D, '            precondition(UInt(bitPattern: position) < UInt(bitPattern: order.count), "Index out of range")', "", mode="stmt"),
    Mutant("orderiteratorholes", D, "                    if key >= 0 { return base._vertex(atKey: key) }", "                    return base._vertex(atKey: key)", mode="stmt"),
    Mutant("orderiteratorstart", D, "Iterator(base: base, slots: order.slots, slot: order.first)", "Iterator(base: base, slots: order.slots, slot: 0)"),
    Mutant("ordercontains", D, "base._key(of: element) != nil", "true"),
    Mutant("safesuccessors", D, "_base._key(of: vertex).map { _base._successors(ofKey: $0) }", "Optional<Base.Successors>.none"),
    Mutant("safeoutedges", D, "_base._key(of: vertex).map { _base._outEdges(ofKey: $0) }", "Optional<Base.OutEdges>.none"),
    Mutant("safeindegree", D, "_base._key(of: vertex).map { _base._inDegree(ofKey: $0) }", "_base._key(of: vertex).map { _base._outDegree(ofKey: $0) }"),

    # MutableDirectedGraph hooks: AdjacencyList.
    Mutant("alvertex", AL, "_vertices[key]", "_vertices[_vertices.count - 1 - key]", nth=0, module="AdjacencyListModule"),
    Mutant("alsuccessors", AL, "Neighbors(vertices: _vertices, slots: _out[row: key])", "Neighbors(vertices: _vertices, slots: _out[row: _vertices.count - 1 - key])", module="AdjacencyListModule"),
    Mutant("alsuccessorkeys", AL, "_out[row: key]", "_out[row: _vertices.count - 1 - key]", nth=1, module="AdjacencyListModule"),
    Mutant("alpredecessorkeys", AL, "_in[row: key]", "_in[row: _vertices.count - 1 - key]", nth=1, module="AdjacencyListModule"),
    Mutant("alinedges", AL, "_inEdges[row: key]", "_inEdges[row: _vertices.count - 1 - key]", module="AdjacencyListModule"),
    Mutant("aloutdegree", AL, "_out.count(ofRow: key)", "_out.count(ofRow: _vertices.count - 1 - key)", module="AdjacencyListModule"),
    Mutant("alindegree", AL, "_in.count(ofRow: key)", "_in.count(ofRow: _vertices.count - 1 - key)", module="AdjacencyListModule"),
    Mutant("alsourcekey", AL, "_records[position].source", "_records[_records.count - 1 - position].source", nth=2, module="AdjacencyListModule"),
    Mutant("altargetkey", AL, "_records[position].target", "_records[_records.count - 1 - position].target", nth=1, module="AdjacencyListModule"),
    Mutant("alinsertedge", AL, "_insertEdge(slots: source, target)", "_insertEdge(slots: target, source)", nth=1, module="AdjacencyListModule"),
    Mutant("almovednil", AL, "key == last ? nil : last", "nil", module="AdjacencyListModule"),
    Mutant("almovedlast", AL, "key == last ? nil : last", "last", module="AdjacencyListModule"),
    Mutant("alremoveedgecheck", AL, '        precondition(UInt(bitPattern: position) < UInt(bitPattern: _records.count), "Edge position out of range")', "", mode="stmt", module="AdjacencyListModule"),

    # MutableDirectedGraph hooks: DirectedPseudograph.
    Mutant("psvertex", PS, "_vertices[key]", "_vertices[_vertices.count - 1 - key]", nth=0, module="Multigraphs"),
    Mutant("pssuccessors", PS, "Neighbors(vertices: _vertices, slots: _out[row: key])", "Neighbors(vertices: _vertices, slots: _out[row: _vertices.count - 1 - key])", module="Multigraphs"),
    Mutant("pssuccessorkeys", PS, "_out[row: key]", "_out[row: _vertices.count - 1 - key]", nth=1, module="Multigraphs"),
    Mutant("pspredecessorkeys", PS, "_in[row: key]", "_in[row: _vertices.count - 1 - key]", nth=1, module="Multigraphs"),
    Mutant("psinedges", PS, "_inEdges[row: key]", "_inEdges[row: _vertices.count - 1 - key]", module="Multigraphs"),
    Mutant("psoutdegree", PS, "_out.count(ofRow: key)", "_out.count(ofRow: _vertices.count - 1 - key)", module="Multigraphs"),
    Mutant("psindegree", PS, "_in.count(ofRow: key)", "_in.count(ofRow: _vertices.count - 1 - key)", module="Multigraphs"),
    Mutant("pssourcekey", PS, "_records[position].source", "_records[_records.count - 1 - position].source", nth=2, module="Multigraphs"),
    Mutant("pstargetkey", PS, "_records[position].target", "_records[_records.count - 1 - position].target", nth=1, module="Multigraphs"),
    Mutant("psinsertedge", PS, "_insertEdge(slots: source, target)", "_insertEdge(slots: target, source)", nth=1, module="Multigraphs"),
    Mutant("psmovednil", PS, "key == last ? nil : last", "nil", module="Multigraphs"),
    Mutant("psmovedlast", PS, "key == last ? nil : last", "last", module="Multigraphs"),

    # MutableDirectedGraph hooks: StableDirectedGraph.
    Mutant("stsuccessors", ST, "Neighbors(pages: _vertexPages, base: _vertexBase, row: _outRow(key))", "Neighbors(pages: _vertexPages, base: _vertexBase, row: _inRow(key))", module="StableGraphs"),
    Mutant("stpredecessors", ST, "Neighbors(pages: _vertexPages, base: _vertexBase, row: _inRow(key))", "Neighbors(pages: _vertexPages, base: _vertexBase, row: _outRow(key))", nth=1, module="StableGraphs"),
    Mutant("stsuccessorkeys", ST, "_outPages.withUnsafeBufferPointer { _LiveRow.Ends(ends: $0[k].endSlice(l), count: $0[k].degree(l)) }", "_outPages.withUnsafeBufferPointer { _LiveRow.Ends(ends: $0[k].endSlice(l), count: 0) }", module="StableGraphs"),
    Mutant("stpredecessorkeys", ST, "_inPages.withUnsafeBufferPointer { _LiveRow.Ends(ends: $0[k].endSlice(l), count: $0[k].degree(l)) }", "_inPages.withUnsafeBufferPointer { _LiveRow.Ends(ends: $0[k].endSlice(l), count: 0) }", module="StableGraphs"),
    Mutant("stinedges", ST, "_inEdges(slot: key)", "_inEdges(slot: _vertexBase)", module="StableGraphs"),
    Mutant("stindegree", ST, "_inDegree(key)", "_outDegree(key)", module="StableGraphs"),
    Mutant("stoutdegree", ST, "_outDegree(key)", "_inDegree(key)", nth=0, module="StableGraphs"),
    Mutant("stsourcekey", ST, "_liveRecord(position).source", "_liveRecord(position).target", module="StableGraphs"),
    Mutant("sttargetkey", ST, "_liveRecord(position).target", "_liveRecord(position).source", nth=1, module="StableGraphs"),
    Mutant("stinsertedge", ST, "_insertEdge(slots: source, target)", "_insertEdge(slots: target, source)", module="StableGraphs"),
    Mutant("stmoved", ST, "        _ = _removeSlot(key)\n        return nil", "        _ = _removeSlot(key)\n        return 0", mode="stmt", module="StableGraphs"),
    Mutant("stremovelookup", ST, "        _slots.removeValue(forKey: _vertex(atSlot: key))", "", mode="stmt", module="StableGraphs"),
]
