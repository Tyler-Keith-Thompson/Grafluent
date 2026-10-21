# Planted bugs for EliasFanoGraphModule: the row width, the two bit writers and readers across a
# word boundary, the unary decoding in the walk and in the iterator, the queries that decode a
# row, the edge iterator's row changes, equality, and the range guards of the checked spellings.
# Run with `just mutate EliasFanoGraphModule`. See scripts/mutate.py.
#
# Known equivalent mutants are not planted: dropping the target range check of edgeIndex(of:) (a
# target outside the graph is never decoded from a row, so the row decode returns nil anyway).

TESTS = ["EliasFanoGraphTests"]

E = "EliasFanoGraph.swift"
D = "EliasFanoGraph+DirectedGraph.swift"

MUTANTS = [
    # The width: ⌊log₂(n / d)⌋.
    Mutant("widthratio", E, "Int.bitWidth &- 1 &- (n / degree).leadingZeroBitCount", "Int.bitWidth &- (n / degree).leadingZeroBitCount"),
    # Section starts.
    Mutant("upperlength", E, "degree &+ ((n &- 1) >> l) &+ 1", "degree &+ ((n &- 1) >> l)"),
    Mutant("lowerlength", E, "lowerStart[v] &+ degree &* l", "lowerStart[v] &+ degree"),
    # Writing and reading across a word boundary.
    Mutant("writespill", E, "words[word &+ 1] |= value >> (64 &- shift)", "", mode="stmt"),
    Mutant("readspill", E, "value |= words[word &+ 1] << (64 &- shift)", "", mode="stmt"),
    Mutant("readmask", E, "value & ((1 << UInt64(width)) &- 1)", "value"),
    Mutant("highbit", E, "upBit &+ high &+ i", "upBit &+ high"),
    # The walk's unary decoding.
    Mutant("walkhigh", E, "bit &- upStart &- i", "bit &- upStart"),
    Mutant("walkclear", E, "word &= word &- 1", "word &= word &- 2", mode="stmt"),
    Mutant("walkmask", E, "upper[bit >> 6] & (UInt64.max << UInt64(bit & 63))", "upper[bit >> 6]"),
    Mutant("walklow", E, "target |= Int(Self._read(width: l, at: lowBit, from: lower))", "target |= Int(Self._read(width: l, at: lowBit &+ l, from: lower))", mode="stmt"),
    # The iterator's.
    Mutant("iterhigh", E, "(bit &- _upStart &- _index) << _width", "(bit &- _upStart) << _width"),
    Mutant("iterlow", E, "_lowBit &+= _width", "_lowBit &+= 1", mode="stmt"),
    Mutant("iterremaining", E, "guard _remaining > 0 else { return nil }", "guard _remaining >= 0 else { return nil }", mode="stmt"),
    Mutant("iterword", E, "_wordBase &+= 64", "_wordBase &+= 63", mode="stmt"),
    # The queries.
    Mutant("edgeindexfound", E, "if found < 0 && target == edge.target { found = start &+ k }", "if target == edge.target { found = k }", mode="stmt"),
    Mutant("targetcount", E, "_decodeRow(v, count: wanted &+ 1) { found = $0 }", "_decodeRow(v, count: wanted &+ 2) { found = $0 }", mode="stmt"),
    Mutant("sourcesearch", E, "if offsets[middle] <= edgeIndex { low = middle } else { high = middle &- 1 }", "if offsets[middle] < edgeIndex { low = middle } else { high = middle &- 1 }", mode="stmt"),
    Mutant("bitsperedge", E, "Double(_lowerStart[vertexCount] &+ _upperStart[vertexCount])", "Double(_lowerStart[vertexCount])"),
    # The edge iterator.
    Mutant("edgesskip", E, "_remainingSkip > 0", "false"),
    Mutant("edgesrow", E, "_rowEnd <= _position", "_rowEnd < _position"),
    Mutant("edgesfirstsource", E, "_remainingSkip = bounds.lowerBound &- graph._offsets[source]", "_remainingSkip = 0", mode="stmt"),
    # Equality.
    Mutant("equalupper", E, "lhs._offsets == rhs._offsets && lhs._lower == rhs._lower && lhs._upper == rhs._upper", "lhs._offsets == rhs._offsets && lhs._lower == rhs._lower"),
    # Checked spellings and the index hooks.
    Mutant("checkedsuccessors", D, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("checkedtarget", D, "guard edgeIndex >= 0 && edgeIndex < edgeCount else { throw EdgeNotFound() }", "", mode="stmt", nth=1),
    Mutant("hookcount", D, "_decodeRow(index, count: _offsets[index &+ 1] &- _offsets[index], body)", "_decodeRow(index, count: _offsets[index &+ 1] &- _offsets[index] &- 1, body)", mode="stmt"),
]
