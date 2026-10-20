# Planted bugs for PackedCompressedSparseRowModule: the packed row pool's rebalancing (the window
# search, the density thresholds, the even spread of spare cells with the favoured row's share,
# growth and shrinking, moving the last row into a removed slot) and the graph's bookkeeping over it
# (records, the pair table, maps). Run with `just mutate PackedCompressedSparseRowModule`; see
# scripts/mutate.py.
#
# Not planted, being equivalent or time only: the leaf window's minimum size and the exact
# thresholds (any thresholds between the live count and the capacity give the same graph, only a
# different layout), and the preconditions that restate what the tiling guarantees.

TESTS = ["PackedCompressedSparseRowTests"]

RP = "PackedRowPool.swift"
GR = "PackedCompressedSparseRow.swift"

MUTANTS = [
    # The pool.
    Mutant("appendnoroom", RP, "rows[row].count == rows[row].capacity", "false"),
    Mutant("appendoffset", RP, "        live += 1\n        return block.count", "        live += 1\n        return block.count &+ 1", mode="stmt"),
    Mutant("swapmoved", RP, "offset < lastOffset", "offset <= lastOffset"),
    Mutant("swapwrite", RP, "            targets[block.start + offset] = target", "", mode="stmt"),
    Mutant("swapposition", RP, "            positions[block.start + offset] = position", "", mode="stmt"),
    Mutant("movelastskip", RP, "row != last", "false"),
    Mutant("movelastroom", RP, "rows[row].capacity < count", "false"),
    Mutant("movelastcount", RP, "            rows[row].count = count", "", mode="stmt"),
    Mutant("anchor", RP, "Swift.min(rows[row].start + rows[row].count, capacity - 1)", "rows[row].start + rows[row].count"),
    Mutant("windowcount", RP, "rows[row].count", "0", nth=9),
    Mutant("windowleft", RP, "                    count += rows[r0].count", "", mode="stmt"),
    Mutant("windowright", RP, "                    count += rows[r1].count", "", mode="stmt"),
    Mutant("windowto", RP, "Swift.max(b, rows[r1 - 1].start + rows[r1 - 1].capacity)", "rows[r1 - 1].start + rows[r1 - 1].capacity"),
    Mutant("density", RP, "Double(count + needed) <= threshold * Double(to - from)", "Double(count) <= threshold * Double(to - from)"),
    Mutant("compactstart", RP, "                            rows[r].start = cursor", "", mode="stmt"),
    Mutant("sharereserved", RP, "(i == favoured ? reserved : 0) + base + (i < remainder ? 1 : 0)", "base + (i < remainder ? 1 : 0)"),
    Mutant("sharerest", RP, "gaps - reserved", "gaps"),
    Mutant("layoutextra", RP, "rows[r] = _Row(start: cursor, count: block.count, capacity: block.count + extra)", "rows[r] = _Row(start: cursor, count: block.count, capacity: block.count)"),
    Mutant("redistributeextra", RP, "block.count + share[i]", "block.count + share[k - 1 - i]"),
    Mutant("layoutcursor", RP, "                            cursor += block.count + extra", "                            cursor += block.count", mode="stmt"),
    Mutant("redistributeread", RP, "                                positions[start + c] = positions[block.start + c]", "", mode="stmt"),
    Mutant("spreadend", RP, "                        end = start", "", mode="stmt"),
    Mutant("shrinknever", RP, "live * 4 < capacity", "false"),
    Mutant("growsize", RP, "while Double(live + needed) > 0.7 * Double(size) { size *= 2 }", "while Double(live + needed) > Double(size) { size *= 2 }", mode="stmt"),
    Mutant("removeallcount", RP, "        for row in rows.indices { rows[row].count = 0 }", "", mode="stmt", nth=0),
    # The graph.
    Mutant("insertexisting", GR, "if let existing = _position(ofPair: pair) { return existing }", "", mode="stmt"),
    Mutant("insertin", GR, "_in.append(target: source, position: position, toRow: target)", "_in.append(target: target, position: position, toRow: target)"),
    Mutant("insertpair", GR, "        _edges.insert(pair, position)", "", mode="stmt"),
    Mutant("removeslotin", GR, "        while let position = _in.lastPosition(ofRow: slot) { _detach(position) }", "", mode="stmt"),
    Mutant("renamesource", GR, "                    _in[target: record.target, record.in] = slot", "", mode="stmt"),
    Mutant("renametarget", GR, "_out[target: record.source == slot ? last : record.source, record.out] = slot", "_out[target: record.source, record.out] = slot"),
    Mutant("movein", GR, "        _in.moveLastRow(into: slot)", "", mode="stmt"),
    Mutant("detachmovedout", GR, "            if let movedOut { records[movedOut.position].out = record.out }", "", mode="stmt"),
    Mutant("detachmovedin", GR, "            if let movedIn { records[movedIn.position].in = record.in }", "", mode="stmt"),
    Mutant("detachlast", GR, "            guard position != last else { return nil }", "", mode="stmt"),
    Mutant("detachupdate", GR, "            _edges.updateValue(position, forKey: moved.pair)", "", mode="stmt"),
    Mutant("mapsappend", GR, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaultsToOwnTable(count: 1) }", "", mode="stmt"),
    Mutant("mapsremove", GR, "        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }", "", mode="stmt", nth=0),
    Mutant("equalcount", GR, "guard lhs.vertexCount == rhs.vertexCount, lhs.edgeCount == rhs.edgeCount else { return false }", "", mode="stmt"),
    Mutant("hashedges", GR, "        hasher.combine(edgeHashes)", "", mode="stmt"),
    Mutant("generationinsert", GR, "_generation.advance(writing: _out.rows)", "()", nth=0),
]
