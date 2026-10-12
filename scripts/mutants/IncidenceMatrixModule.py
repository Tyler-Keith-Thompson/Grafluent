# Planted bugs for IncidenceMatrixModule; run with `just mutate IncidenceMatrixModule`. See
# scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   storagenegative   the column half of the negative-shape check: every column count is the other
#                     plane's row count, which the same check traps on first.
#   storagebytes      the byte-count overflow check: allocating that many words traps the same; the
#                     check only names the shape.
#   rowspare          a row's BitSet over the whole stride: the words past the last column are zero.
#   appendrowwidth    a spare word per appended row: it lies past every row's used words; memory only.
#   restrideskip      restriding to the same stride, keeping the stride on a full reset, and not
#   removestride      restriding on reserve: the used words are the same; time and memory only.
#   reservestride
#   unionwords        reading the other plane at this plane's stride, in the union and in the
#   oforeachstride    oriented member scan: the two planes always share their strides (every
#                     append, reset and reserve goes to both).
#   copysame          copying a matrix through the generic path instead of returning it: equal.
#   containssize      comparing columns without the cached-size filter: time only.
#   eqcells           equality without the cell-count fast reject: the bit comparison covers it.
#   hashcolumns       hashing the columns instead of the rows: they determine each other.
#   memberrankcheck   preconditions of the underscored rank, select and scan hooks: their callers
#   memberindexcheck  (the views, the algorithms) only pass members and positions in range.
#   foreachcheck
#   oforeachcheck
#
# Removed as dead code after planting: the members' range precondition in
# `init(vertexCount:hyperedges:)` and the pre-checks of `insert(hyperedge:)` and
# `insert(sources:targets:)` (the bit write traps on the same members), the shape precondition of
# the planes' union (both planes always share a shape), and the decoder's `v >= 0` (a negative
# member already fails the strictly-ascending check, whose `previous` starts at -1).

TESTS = ["IncidenceMatrixTests"]

R = "BitRows.swift"
M = "IncidenceMatrix.swift"
O = "OrientedIncidenceMatrix.swift"

MUTANTS = [
    # The bit planes.
    Mutant("wordsneeded", R, "(columns + UInt.bitWidth - 1) / UInt.bitWidth", "columns / UInt.bitWidth"),
    Mutant("storagenegative", R, "rows >= 0 && columns >= 0", "rows >= 0"),
    Mutant("storagebytes", R, "!words.overflow && !words.partialValue.multipliedReportingOverflow(by: MemoryLayout<UInt>.size).overflow", "!words.overflow"),
    Mutant("mask", R, "column & (UInt.bitWidth - 1)", "column & (UInt.bitWidth - 2)"),
    Mutant("wordindex", R, "row &* wordsPerRow &+ (column / UInt.bitWidth)", "row &* wordsPerRow"),
    Mutant("setunchanged", R, "        guard new != old else { return false }", "", mode="stmt"),
    Mutant("setclear", R, "value ? old | mask : old & ~mask", "old ^ mask"),
    Mutant("rowspare", R, "return BitSet(words: words[start ..< start &+ Self.wordsNeeded(columnCount)])", "return BitSet(words: words[start ..< start &+ wordsPerRow])", mode="stmt"),
    Mutant("appendrowwidth", R, "words.append(contentsOf: repeatElement(0, count: wordsPerRow))", "words.append(contentsOf: repeatElement(0, count: wordsPerRow &+ 1))", mode="stmt"),
    Mutant("appendcolumngrow", R, "columnCount &+ 1 > wordsPerRow &* UInt.bitWidth", "columnCount > wordsPerRow &* UInt.bitWidth"),
    Mutant("restrideskip", R, "        guard newWordsPerRow != wordsPerRow else { return }", "", mode="stmt"),
    Mutant("restrideused", R, "Swift.min(Self.wordsNeeded(columnCount), newWordsPerRow)", "Swift.min(Self.wordsNeeded(columnCount), newWordsPerRow) &- 1"),
    Mutant("restridestride", R, "moved[r &* newWordsPerRow &+ w] = words[r &* wordsPerRow &+ w]", "moved[r &* newWordsPerRow &+ w] = words[r &* newWordsPerRow &+ w]", mode="stmt"),
    Mutant("removerows", R, "        rowCount = 0", "", mode="stmt"),
    Mutant("removestride", R, "        if !keepingCapacity { wordsPerRow = 0 }", "", mode="stmt"),
    Mutant("reservestride", R, "        if needed > wordsPerRow { restride(needed) }", "", mode="stmt"),
    Mutant("samecolumns", R, "columnCount == other.columnCount", "true"),
    Mutant("samestride", R, "other.words[r &* other.wordsPerRow &+ w]", "other.words[r &* wordsPerRow &+ w]"),
    Mutant("hashspare", R, "            for w in 0 ..< used { hasher.combine(words[r &* wordsPerRow &+ w]) }", "            for w in 0 ..< wordsPerRow { hasher.combine(words[r &* wordsPerRow &+ w]) }", mode="stmt"),
    Mutant("hashwords", R, "            for w in 0 ..< used { hasher.combine(words[r &* wordsPerRow &+ w]) }", "", mode="stmt"),

    Mutant("unionwords", R, "words[r &* stride &+ w] |= otherWords[r &* otherStride &+ w]", "words[r &* stride &+ w] |= otherWords[r &* stride &+ w]", mode="stmt"),
    Mutant("rankpartial", R, "(words[start &+ whole] & (Self.mask(partial) &- 1)).nonzeroBitCount", "(words[start &+ whole] & Self.mask(partial)).nonzeroBitCount"),
    Mutant("rankskipwords", R, "for w in 0 ..< whole { count &+= words[start &+ w].nonzeroBitCount }", "", mode="stmt"),
    Mutant("selectskip", R, "remaining >= count", "remaining > count"),
    Mutant("selectclear", R, "word &= word &- 1\n                    remaining &-= 1", "remaining &-= 1", mode="stmt"),
    Mutant("selectword", R, "return w &* UInt.bitWidth &+ word.trailingZeroBitCount", "return word.trailingZeroBitCount", mode="stmt"),
    Mutant("popcountrow", R, "for w in 0 ..< Self.wordsNeeded(columnCount) { count &+= words[start &+ w].nonzeroBitCount }", "for w in 0 ..< Swift.min(1, Self.wordsNeeded(columnCount)) { count &+= words[start &+ w].nonzeroBitCount }", mode="stmt"),

    # IncidenceMatrix: construction.
    Mutant("buildcolumn", M, "for k in offsets[p] ..< offsets[p + 1] { _setCell(flat[k], p, to: true) }", "for k in offsets[p] ..< offsets[p + 1] { _setCell(flat[k], 0, to: true) }", mode="stmt"),
    Mutant("graphsecond", M, "            _setCell(v, p, to: true)", "            _setCell(u, p, to: true)", mode="stmt"),
    Mutant("digraphtarget", M, "_setCell(graph.targetIndex(ofEdgeAt: position), p, to: true)", "_setCell(graph.sourceIndex(ofEdgeAt: position), p, to: true)", mode="stmt"),
    Mutant("copysame", M, "hypergraph as? IncidenceMatrix", "Optional<IncidenceMatrix>.none"),
    Mutant("copycolumn", M, "for v in hypergraph.memberIndices(ofHyperedgeAt: position) { _setCell(v, p, to: true) }", "for v in hypergraph.memberIndices(ofHyperedgeAt: position) { _setCell(v, 0, to: true) }", mode="stmt"),
    Mutant("copydirectedtargets", M, "for v in hypergraph.targetIndices(ofHyperedgeAt: position) { _setCell(v, p, to: true) }", "", mode="stmt"),

    Mutant("fromorientedrows", M, "        _rows.formUnion(targets._rows)", "", mode="stmt"),
    Mutant("fromorientedcolumns", M, "        _columns.formUnion(targets._columns)", "", mode="stmt"),
    Mutant("fromorienteddegrees", M, "            _degrees[v] = count", "", mode="stmt"),
    Mutant("fromorientedsizes", M, "for p in 0 ..< _columns.rowCount { _sizes[p] = _columns.popCount(ofRow: p) }", "", mode="stmt"),
    Mutant("fromorientedcount", M, "        _cellCount = total", "", mode="stmt"),

    # IncidenceMatrix: the cell write and the checks.
    Mutant("cellcolumn", M, "        _columns.set(p, v, to: value)", "", mode="stmt"),
    Mutant("celldelta", M, "value ? 1 : -1", "1"),
    Mutant("celldegree", M, "        _degrees[v] &+= delta", "", mode="stmt"),
    Mutant("cellsize", M, "        _sizes[p] &+= delta", "", mode="stmt"),
    Mutant("cellcount", M, "        _cellCount &+= delta", "", mode="stmt"),
    Mutant("checkvertexlow", M, "vertex >= 0 && vertex < _rows.rowCount", "vertex < _rows.rowCount", nth=0),
    Mutant("checkvertexhigh", M, "vertex >= 0 && vertex < _rows.rowCount", "vertex >= 0", nth=0),
    Mutant("checkhyperedgelow", M, "position >= 0 && position < _columns.rowCount", "position < _columns.rowCount", nth=0),
    Mutant("checkhyperedgehigh", M, "position >= 0 && position < _columns.rowCount", "position >= 0", nth=0),

    # IncidenceMatrix: reads.
    Mutant("cell", M, "return _rows.bit(vertex, position)", "return _columns.bit(position, vertex) != _rows.bit(vertex, position)", mode="stmt"),
    Mutant("members", M, "_columns.row(position)", "_rows.row(position)", nth=0),
    Mutant("incident", M, "        return _rows.row(vertex)", "        return _columns.row(vertex)", mode="stmt"),
    Mutant("size", M, "        return _sizes[position]", "        return _sizes[position] &+ 1", mode="stmt"),
    Mutant("degree", M, "        return _degrees[vertex]", "        return _degrees[vertex] &+ 1", mode="stmt"),
    Mutant("containslow", M, "vertex >= 0 && vertex < _rows.rowCount", "vertex < _rows.rowCount", nth=1),
    Mutant("containshigh", M, "vertex >= 0 && vertex < _rows.rowCount", "vertex >= 0", nth=1),
    Mutant("containsempty", M, "_sizes.contains(0)", "false"),
    Mutant("containscolumn", M, "_sizes[p] == count && _columns.row(p) == wanted", "_sizes[p] == count"),
    Mutant("containssize", M, "_sizes[p] == count && _columns.row(p) == wanted", "_columns.row(p) == wanted", nth=0),
    Mutant("containsrange", M, "            guard contains(v) else { return false }", "", mode="stmt"),
    Mutant("vertexindexcheck", M, "        _checkVertex(vertex)\n        return vertex", "        return vertex", mode="stmt"),
    Mutant("vertexatcheck", M, "        _checkVertex(index)\n        return index", "        return index", mode="stmt"),
    Mutant("hyperedgeindexcheck", M, "        _checkHyperedge(position)\n        return position", "        return position", mode="stmt"),
    Mutant("hyperedgescheck", M, '            precondition(position >= 0 && position < _columns.rowCount, "Column \\(position) is out of range 0..<\\(_columns.rowCount)")', "", mode="stmt"),

    Mutant("memberindices", M, "MemberIndices(_words: _columns.words(ofRow: position))", "MemberIndices(_words: _rows.words(ofRow: position))"),
    Mutant("incidentindices", M, "MemberIndices(_words: _rows.words(ofRow: index))", "MemberIndices(_words: _columns.words(ofRow: index))"),
    Mutant("incidentindicescheck", M, "        _checkVertex(index)", "", mode="stmt", nth=0),
    Mutant("memberrank", M, "return _columns.popCount(ofRow: position, before: index)", "return _columns.popCount(ofRow: position, before: index &+ 1)", mode="stmt"),
    Mutant("memberrankcheck", M, '        precondition(_columns.bit(position, index), "Vertex \\(index) is not a member of column \\(position)")', "", mode="stmt"),
    Mutant("memberindex", M, "return _columns.column(ofRow: position, atRank: rank)", "return _columns.column(ofRow: position, atRank: 0)", mode="stmt"),
    Mutant("memberindexcheck", M, "rank >= 0 && rank < _sizes[position]", "rank >= 0"),
    Mutant("foreachword", M, "body(k &* UInt.bitWidth &+ word.trailingZeroBitCount)", "body(word.trailingZeroBitCount)", mode="stmt", nth=0),
    Mutant("foreachcheck", M, "        _checkHyperedge(position)", "", mode="stmt", nth=5),

    # SetBits.
    Mutant("setbitsclear", M, "_current &= _current &- 1", "_current &= _current &- 2", mode="stmt"),
    Mutant("setbitsoffset", M, "(_wordIndex &- _words.startIndex) &* UInt.bitWidth &+ bit", "_wordIndex &* UInt.bitWidth &+ bit"),
    Mutant("setbitsfirst", M, "_words.isEmpty ? 0 : _words[_words.startIndex]", "0"),
    Mutant("setbitsend", M, "_wordIndex < _words.endIndex", "_wordIndex < _words.endIndex &- 1"),

    # IncidenceMatrix: mutation.
    Mutant("appendvertexcolumns", M, "        _columns.appendColumn()", "", mode="stmt"),
    Mutant("appendvertexdegree", M, "        _degrees.append(0)", "", mode="stmt"),
    Mutant("insertrows", M, "        _rows.appendColumn()", "", mode="stmt"),
    Mutant("insertsize", M, "        _sizes.append(0)", "", mode="stmt"),
    Mutant("insertcell", M, "return _setCell(vertex, position, to: true)", "_setCell(vertex, position, to: true); return true", mode="stmt"),
    Mutant("removecell", M, "return _setCell(vertex, position, to: false)", "_setCell(vertex, position, to: false); return true", mode="stmt"),
    Mutant("removeallcount", M, "        _cellCount = 0", "", mode="stmt", nth=1),
    Mutant("removealldegrees", M, "        _degrees.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("removeallcolumns", M, "        _columns.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("transposedcounts", M, "IncidenceMatrix(_rows: _columns, _columns: _rows, _degrees: _sizes, _sizes: _degrees, _cellCount: _cellCount)", "IncidenceMatrix(_rows: _columns, _columns: _rows, _degrees: _degrees, _sizes: _sizes, _cellCount: _cellCount)"),

    # IncidenceMatrix: equality, hashing, Codable and the description.
    Mutant("eqcells", M, "lhs._cellCount == rhs._cellCount && lhs._rows.sameBits(as: rhs._rows)", "lhs._rows.sameBits(as: rhs._rows)"),
    Mutant("eqbits", M, "lhs._cellCount == rhs._cellCount && lhs._rows.sameBits(as: rhs._rows)", "lhs._cellCount == rhs._cellCount", nth=0),
    Mutant("hashcolumns", M, "        _rows.hashBits(into: &hasher)", "        _columns.hashBits(into: &hasher)", mode="stmt"),
    Mutant("encodecolumns", M, "(0 ..< hyperedgeCount).map { Array(_columns.row($0)) }", "(0 ..< hyperedgeCount).map { Array(_columns.row($0).dropFirst()) }"),
    Mutant("decodecolumns", M, "            try Self._checkDecodedColumn(column, vertexCount: n, key: .hyperedges, in: container)", "", mode="stmt"),
    Mutant("decodenegative", M, '        guard n >= 0 else {\n            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Negative vertex count")\n        }', "", mode="stmt"),
    Mutant("decoderange", M, "v < n", "true"),
    Mutant("decodeascending", M, "v > previous", "v >= previous"),
    Mutant("decodeprevious", M, "            previous = v", "", mode="stmt"),
    Mutant("describerows", M, "Swift.min(n, limit)", "Swift.min(n, limit &+ 1)"),
    Mutant("describecolumns", M, "Swift.min(m, columnLimit)", "Swift.min(m, columnLimit &+ 1)"),
    Mutant("describecolumnellipsis", M, '        if m > columnLimit { row.append("…") }', "", mode="stmt"),
    Mutant("describerowellipsis", M, '    if n > limit { rows.append("…") }', "", mode="stmt"),
    Mutant("describecell", M, '_rows.bit($0, $1) ? "1" : "0"', '_rows.bit($0, $1) ? "0" : "1"'),

    Mutant("decodelimitkey", M, "decoder.userInfo[Self.maximumDecodedWordCountKey] as? Int ?? Self.defaultMaximumDecodedWordCount", "Self.defaultMaximumDecodedWordCount"),
    Mutant("decodelimit", M, "words <= maximum", "words < maximum"),
    Mutant("decodenolimit", M, "words <= maximum", "true", nth=0),
    Mutant("wordsperrow", M, "m / width + (m % width == 0 ? 0 : 1)", "m / width"),
    Mutant("wordspercolumn", M, "n / width + (n % width == 0 ? 0 : 1)", "n / width"),
    Mutant("wordsrowoverflow", M, "wordsPerRow == 0 || n <= Int.max / wordsPerRow", "true"),
    Mutant("wordscolumnoverflow", M, "wordsPerColumn == 0 || m <= Int.max / wordsPerColumn", "true"),
    Mutant("wordsparts", M, "[rowWords, columnWords, n, m]", "[rowWords, columnWords]"),
    Mutant("wordssumoverflow", M, "part <= Int.max - total", "true"),
    Mutant("wordsplanesoverflow", M, "planes <= 1 || total <= Int.max / planes", "true"),
    Mutant("wordsplanes", M, "return total * planes", "return total", mode="stmt"),

    # OrientedIncidenceMatrix: construction.
    Mutant("obuildtargets", O, "targets.append(Array(hyperedge.targets))", "targets.append(Array(hyperedge.sources))", mode="stmt"),
    Mutant("obuildedges", O, "(sources: CollectionOfOne($0.source), targets: CollectionOfOne($0.target))", "(sources: CollectionOfOne($0.target), targets: CollectionOfOne($0.source))"),
    Mutant("ocopytargets", O, "for v in hypergraph.targetIndices(ofHyperedgeAt: position) { _targets._setCell(v, p, to: true) }", "for v in hypergraph.targetIndices(ofHyperedgeAt: position) { _sources._setCell(v, p, to: true) }", mode="stmt"),
    Mutant("odigraphtarget", O, "_targets._setCell(graph.targetIndex(ofEdgeAt: position), p, to: true)", "_targets._setCell(graph.sourceIndex(ofEdgeAt: position), p, to: true)", mode="stmt"),
    Mutant("ographtarget", O, "_targets._setCell(v, p, to: true)", "_targets._setCell(u, p, to: true)", mode="stmt", nth=1),

    # OrientedIncidenceMatrix: reads.
    Mutant("oentry", O, "(_targets[vertex: vertex, hyperedge: position] ? 1 : 0) - (_sources[vertex: vertex, hyperedge: position] ? 1 : 0)", "(_sources[vertex: vertex, hyperedge: position] ? 1 : 0) - (_targets[vertex: vertex, hyperedge: position] ? 1 : 0)"),
    Mutant("otargets", O, "_targets.members(ofHyperedgeAt: position)", "_sources.members(ofHyperedgeAt: position)"),
    Mutant("otargetindices", O, "_targets.memberIndices(ofHyperedgeAt: position)", "_sources.memberIndices(ofHyperedgeAt: position)"),
    Mutant("oinhyperedges", O, "_targets.incidentHyperedges(of: vertex)", "_sources.incidentHyperedges(of: vertex)"),
    Mutant("oindegree", O, "_targets.degree(of: vertex)", "_sources.degree(of: vertex)"),
    Mutant("odegree", O, "outDegree(of: vertex) &+ inDegree(of: vertex)", "outDegree(of: vertex)"),
    Mutant("ocontainscandidates", O, "candidates = _targets._rows.row(first)", "candidates = _sources._rows.row(first)", mode="stmt"),
    Mutant("ocontainsempty", O, "_sources._sizes[p] == 0 && _targets._sizes[p] == 0", "_sources._sizes[p] == 0"),
    Mutant("ocontainstargets", O, "_targets._columns.row(p) == wantedTargets", "true"),
    Mutant("ocontainssources", O, "_sources._columns.row(p) == wantedSources", "true"),
    Mutant("ohyperedges", O, "(_sources[position], _targets[position])", "(_sources[position], _sources[position])"),

    Mutant("osourcesize", O, "_sources.size(ofHyperedgeAt: position)", "_targets.size(ofHyperedgeAt: position)"),
    Mutant("otargetsize", O, "_targets.size(ofHyperedgeAt: position)", "_sources.size(ofHyperedgeAt: position)", nth=1),
    Mutant("ooutindices", O, "_sources.incidentHyperedgeIndices(ofIndex: index)", "_targets.incidentHyperedgeIndices(ofIndex: index)"),
    Mutant("oinindices", O, "_targets.incidentHyperedgeIndices(ofIndex: index)", "_sources.incidentHyperedgeIndices(ofIndex: index)", nth=1),
    Mutant("omemberrank", O, "targets ? _targets._memberRank(ofIndex: index, inHyperedgeAt: position) : _sources._memberRank(ofIndex: index, inHyperedgeAt: position)", "_sources._memberRank(ofIndex: index, inHyperedgeAt: position)"),
    Mutant("omemberindex", O, "targets ? _targets._memberIndex(atRank: rank, inHyperedgeAt: position) : _sources._memberIndex(atRank: rank, inHyperedgeAt: position)", "_sources._memberIndex(atRank: rank, inHyperedgeAt: position)"),
    Mutant("oforeachunion", O, "sourceWords[sourceStart &+ k] | targetWords[targetStart &+ k]", "sourceWords[sourceStart &+ k]"),
    Mutant("oforeachstride", O, "position &* targets.wordsPerRow", "position &* sources.wordsPerRow"),
    Mutant("oforeachcheck", O, "        _sources._checkHyperedge(position)", "", mode="stmt"),

    # OrientedIncidenceMatrix: mutation.
    Mutant("oappendvertex", O, "        _sources.appendVertex()", "", mode="stmt"),
    Mutant("oinserttargets", O, "return _targets.insert(hyperedge: targets)", "return _targets.insert(hyperedge: sources)", mode="stmt"),
    Mutant("oinsertedge", O, "insert(sources: CollectionOfOne(edge.source), targets: CollectionOfOne(edge.target))", "insert(sources: CollectionOfOne(edge.target), targets: CollectionOfOne(edge.source))"),
    Mutant("oinsertsource", O, "_sources.insert(vertex, intoHyperedgeAt: position)", "_targets.insert(vertex, intoHyperedgeAt: position)"),
    Mutant("oinserttarget", O, "_targets.insert(vertex, intoHyperedgeAt: position)", "_sources.insert(vertex, intoHyperedgeAt: position)", nth=1),
    Mutant("oremovesource", O, "_sources.remove(vertex, fromHyperedgeAt: position)", "_targets.remove(vertex, fromHyperedgeAt: position)"),
    Mutant("oremovetarget", O, "_targets.remove(vertex, fromHyperedgeAt: position)", "_sources.remove(vertex, fromHyperedgeAt: position)", nth=1),
    Mutant("oremoveall", O, "        _targets.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("otransposed", O, "OrientedIncidenceMatrix(_sources: _sources.transposed(), _targets: _targets.transposed())", "OrientedIncidenceMatrix(_sources: _sources.transposed(), _targets: _targets)"),
    Mutant("oreversed", O, "OrientedIncidenceMatrix(_sources: _targets, _targets: _sources)", "OrientedIncidenceMatrix(_sources: _sources, _targets: _targets)"),

    # OrientedIncidenceMatrix: equality, hashing, Codable and the description.
    Mutant("oeq", O, "lhs._sources == rhs._sources && lhs._targets == rhs._targets", "lhs._sources == rhs._sources"),
    Mutant("ohashtargets", O, "        hasher.combine(_targets)", "", mode="stmt"),
    Mutant("oencodetargets", O, "Array(targets(ofHyperedgeAt: $0))", "Array(sources(ofHyperedgeAt: $0))"),
    Mutant("odecodelengths", O, "sources.count == targets.count", "true"),
    Mutant("odecodesources", O, "        for column in sources { try IncidenceMatrix._checkDecodedColumn(column, vertexCount: n, key: .sources, in: container) }", "", mode="stmt"),
    Mutant("odecodetargets", O, "        for column in targets { try IncidenceMatrix._checkDecodedColumn(column, vertexCount: n, key: .targets, in: container) }", "", mode="stmt"),
    Mutant("odecodelimitkey", O, "decoder.userInfo[IncidenceMatrix.maximumDecodedWordCountKey] as? Int ?? IncidenceMatrix.defaultMaximumDecodedWordCount", "IncidenceMatrix.defaultMaximumDecodedWordCount"),
    Mutant("odecodeshape", O, "        try IncidenceMatrix._checkDecodedShape(n, sources.count, planes: 2, maximum: maximum, key: .vertexCount, in: container)", "", mode="stmt"),
    Mutant("odecodeplanes", O, "        try IncidenceMatrix._checkDecodedShape(n, sources.count, planes: 2, maximum: maximum, key: .vertexCount, in: container)", "        try IncidenceMatrix._checkDecodedShape(n, sources.count, planes: 1, maximum: maximum, key: .vertexCount, in: container)", mode="stmt"),
    Mutant("odescribe", O, 'entry < 0 ? "-" : entry > 0 ? "+" : "0"', 'entry < 0 ? "+" : entry > 0 ? "-" : "0"'),
]
