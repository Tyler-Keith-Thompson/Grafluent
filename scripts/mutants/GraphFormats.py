# Planted bugs for GraphFormats: the scanners (UTF-8, lines, XML, JSON, the shared key index), every
# reader and writer, the limits (Matrix Market's vertex bound, the expansion budget), the decimal
# parser and Schubfach, and the bulk hooks in AdjacencyListModule and Multigraphs the line readers
# build through. Run with `just mutate GraphFormats`; see scripts/mutate.py.
#
# `--all` (2026-10-11): 89 of 91 caught. Known equivalent mutants (they survive by design):
# - undirectedreserve: no reader reserves an incremental undirected target (Matrix Market, the one
#   reader that reserves from a count, builds through the bulk target), so emptying
#   `_UndirectedTarget.reserve` changes nothing observable.
# - sfinteger: sends the doubles in [1, 2) that are integers (only 1.0) through Schubfach's general
#   path, which gives the same shortest digits as the integer shortcut.

TESTS = ["GraphFormatsTests"]

U = "UTF8Validation.swift"
TL = "TextLines.swift"
MM = "MatrixMarket.swift"
EL = "EdgeList.swift"
AL = "AdjacencyListFormat.swift"
DOT = "DOT.swift"
GML = "GraphML.swift"
XML = "XMLScanner.swift"
JS = "JSONScanner.swift"
NL = "NodeLinkJSON.swift"
MD = "Mermaid.swift"
KI = "KeyIndex.swift"
EB = "ExpansionBudget.swift"
DP = "DecimalParsing.swift"
DF = "DoubleFormatting.swift"
RT = "ReadTarget.swift"
WS = "WriteSource.swift"
SK = "ScalarKey.swift"
OB = "OutputBuffer.swift"
IDT = "IDTable.swift"
FO = "FileOrderConstruction.swift"
PM = "Pseudograph+MutableGraph.swift"

MUTANTS = [
    # UTF-8 and positions.
    Mutant("utf8surrogate", U, "high = 0x9F", "", mode="stmt"),
    Mutant("utf8overlong", U, "low = 0xA0", "", mode="stmt"),
    Mutant("utf8cut", U, "guard i &+ width <= n else { throw ParseError(.invalidUTF8, at: i) }", "", mode="stmt"),
    Mutant("xmlcontrol", U, "lead < 0x20 && lead != 0x09", "lead < 0x09 && lead != 0x09"),

    # Line scanning and list fields.
    Mutant("wsnbsp", TL, "b == 0x85 || b == 0xA0", "b == 0x85"),
    Mutant("wsideographic", TL, "q &+ 2 < n && text[q &+ 1] == 0x80 && text[q &+ 2] == 0x80 ? 3 : 0", "0"),
    Mutant("wsvt", TL, "(c &- 0x09) < 5", "(c &- 0x09) < 2"),
    Mutant("wsfs", TL, "(c &- 0x1C) < 4", "false"),
    Mutant("listcomment", TL, "if c == 0x0A || c == UInt8(ascii: \"#\") || _whitespaceWidth(text, q) > 0 { break }",
           "if c == 0x0A || _whitespaceWidth(text, q) > 0 { break }", mode="stmt", nth=0),
    Mutant("listcr", TL, "if end == lineEnd && end > p && text[end &- 1] == 0x0D { end &-= 1 }", "", mode="stmt"),
    Mutant("lexinf", TL, "return .double(negative ? -.infinity : .infinity)",
           "return .string(_string(UnsafeBufferPointer(rebasing: text[start ..< end])))", mode="stmt"),
    Mutant("lexoverflow", TL, "if let parts = _decimalParts(text, start, end) { return .double(_double(parts, text, start, end)) }",
           "if let parts = _decimalParts(text, start, end), _double(parts, text, start, end).isFinite { return .double(_double(parts, text, start, end)) }",
           mode="stmt"),
    Mutant("listtokenws", EL, "!_containsWhitespace(bytes)", "true"),

    # Matrix Market.
    Mutant("mmlimit", MM, "if rows > maximumVertexCount { throw ParseError(.limitExceeded, at: sizeOffset) }", "", mode="stmt"),
    Mutant("mmlimiteq", MM, "rows > maximumVertexCount", "rows >= maximumVertexCount"),
    Mutant("mmfieldcr", MM, "(c == 0x0D && (q &+ 1 == text.count || text[q &+ 1] == 0x0A))", "c == 0x0D"),
    Mutant("mmoverflow", MM, "if o1 || o2 { overflow = true }", "", mode="stmt"),
    Mutant("mmdigits", MM, "digitsOnly = false", "", mode="stmt"),
    Mutant("mmcomment", MM, "if q == lineStart && text[q] == UInt8(ascii: \"%\") { throw ParseError(.syntax, at: lineStart) }", "", mode="stmt"),
    Mutant("mmextra", MM, "if count > width { throw ParseError(.syntax, at: width == 2 ? valueStart : extra) }", "", mode="stmt"),
    Mutant("mmextrapos", MM, "width == 2 ? valueStart : extra", "extra"),
    Mutant("mmshort", MM, "if count < width { throw ParseError(.syntax, at: contentEnd) }", "", mode="stmt"),
    Mutant("mmcontentcr", MM, "if contentEnd > lineStart && text[contentEnd &- 1] == 0x0D { contentEnd &-= 1 }", "", mode="stmt"),
    Mutant("mmrange", MM, "if c < 1 || c > rows { throw ParseError(.indexOutOfRange, at: column.start) }", "", mode="stmt"),
    Mutant("mmmirror", MM, "mirrors && r != c", "mirrors"),
    Mutant("mmskew", MM, ".double(symmetry == .skewSymmetric ? -w : w)", ".double(w)"),
    Mutant("mmidentity", MM, "identity ? r &- 1 : keys[r &- 1]", "identity ? r : keys[r &- 1]"),
    Mutant("mmcount", MM, "if seen < entries { throw ParseError(.entryCountMismatch, at: n) }", "", mode="stmt"),

    # Edge and adjacency lists.
    Mutant("elcount", EL, "if line.count > width { throw ParseError(.syntax, at: line.extraStart) }", "", mode="stmt"),
    Mutant("elshort", EL, "if line.count < width { throw ParseError(.syntax, at: line.contentEnd) }", "", mode="stmt"),
    Mutant("elcolumns", EL, "value(position, k, _lexicalValue(text, s, e))", "value(position, 0, _lexicalValue(text, s, e))", mode="stmt"),
    Mutant("alhead", AL, "_ = target.insertEdge(head, resolved.key)", "_ = target.insertEdge(resolved.key, head)", mode="stmt"),
    Mutant("alline", AL, "while q < n && text[q] != 0x0A { q &+= 1 }", "", mode="stmt"),

    # Bulk target and replay.
    Mutant("bulkalias", RT, "keys[vertex] = existing\n            return (existing, false)", "return (key, false)", mode="stmt"),
    Mutant("bulkreplay", RT, "for entry in entries { body(positions[entry.edge], names[entry.name], entry.value) }",
           "for entry in entries { body(positions[0], names[entry.name], entry.value) }", mode="stmt"),
    Mutant("bulkpositions", RT, "!buffer.entries.isEmpty", "false", nth=0),
    Mutant("undirectedreserve", RT, "graph.reserveCapacity(vertexCount: vertexCount, edgeCount: edgeCount)", "", mode="stmt", nth=1),

    # Rows built by counting sort (AdjacencyListModule, Multigraphs).
    Mutant("arcrowsoutedge", FO, "outEdgeStorage[o] = p", "outEdgeStorage[o] = o", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcrowsin", FO, "inStorage[i] = source", "inStorage[i] = target", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgerowsorder", FO, "neighborStorage[uSlot] = v", "neighborStorage[uSlot] = u", mode="stmt", module="AdjacencyListModule"),
    Mutant("distinctorient", FO, "undirected && b < a ? _SlotPair(b, a) : _SlotPair(a, b)", "_SlotPair(a, b)", module="AdjacencyListModule"),
    Mutant("distinctposition", FO, "if reportingPositions { positions.append(table.value(at: index)) }",
           "if reportingPositions { positions.append(i) }", mode="stmt", module="AdjacencyListModule"),
    Mutant("parallelkey", PM, "u <= v ? _SlotPair(u, v) : _SlotPair(v, u)", "_SlotPair(u, v)", module="Multigraphs"),

    # DOT.
    Mutant("dotdefaultplace", DOT, "nodeDefaults[place].1 = v", "nodeDefaults.append((k, v))", mode="stmt"),
    Mutant("dotdefaultscalar", DOT, "edgeDefaultIndex[_ScalarKey(k)]", "edgeDefaults.firstIndex(where: { $0.0 == k })", nth=0),
    Mutant("dotbudgetvertex", DOT, "try budget.spend(defaults.count, at: statement)", "", mode="stmt"),
    Mutant("dotbudgetedge", DOT, "try budget.spend(edgeDefaults.count &+ pairs.count, at: lexeme.start)",
           "try budget.spend(edgeDefaults.count, at: lexeme.start)", mode="stmt"),
    Mutant("dotidcheck", DOT, "ids.set(k, id: id.debugDescription) { _appendDOTID(id, to: &$0) }",
           "ids.set(k, id: id.debugDescription) { _appendDOTID(id + \"\\(k)\", to: &$0) }", mode="stmt"),

    # The expansion budget.
    Mutant("budgetfloor", EB, "remaining = overflow ? .max : product &+ 4096", "remaining = overflow ? .max : product &+ 1_000_000_000", mode="stmt"),
    Mutant("budgetstrict", EB, "if units > remaining { throw ParseError(.limitExceeded, at: offset) }",
           "if units > remaining &* 2 { throw ParseError(.limitExceeded, at: offset) }", mode="stmt"),

    # GraphML.
    Mutant("gmlstamp", GML, "stamps[groups[k]] = generation", "", mode="stmt"),
    Mutant("gmlgroupname", GML, "groupsByName[_ScalarKey(key.name)]", "groupsByName.first(where: { $0.key.string == key.name })?.value", nth=0),
    Mutant("gmldefaultdomain", GML, "domain == .graph ? 0 : domain == .node ? 1 : 2", "domain == .graph ? 0 : 1"),
    Mutant("gmlbudget", GML, "try budget.spend(applicable.count, at: offset)", "", mode="stmt"),
    Mutant("gmlboolean", GML, "if word.elementsEqual(\"true\".utf8) || word.elementsEqual(\"1\".utf8) { return true }",
           "if word.elementsEqual(\"true\".utf8) { return true }", mode="stmt"),
    Mutant("gmlcollapse", GML, "while s < e && _isXMLSpace(text[s]) { s += 1 }", "", mode="stmt"),

    # XML and JSON key indexes.
    Mutant("kiopen", KI, "open[slots[slot].generation]", "slots[slot].generation != 0"),
    Mutant("kigeneration", KI, "if entry.generation == generation && entry.hash == hash && matches(entry.key) { return entry.key }",
           "if entry.hash == hash && matches(entry.key) { return entry.key }", mode="stmt"),
    Mutant("kigrowsort", KI, "depth[$0.generation]! < depth[$1.generation]!", "depth[$0.generation]! > depth[$1.generation]!"),
    Mutant("kiend", KI, "open[frame.generation] = false", "", mode="stmt"),
    Mutant("jsonindexed", JS, "if indexed.removeLast() { index.end() }", "_ = indexed.removeLast()", mode="stmt"),
    Mutant("jsonthreshold", JS, "existing < 16", "existing < 1000"),
    Mutant("xmlindexend", XML, "nameIndex.end()", "", mode="stmt"),

    # Node-link JSON.
    Mutant("nlkeyed", NL, "if let existing = find(pair, name) { return existing }", "", mode="stmt"),
    Mutant("nlnewkey", NL, "while integerPositions[IntegerKey(pair, k)] != nil { k &+= 1 }", "", mode="stmt"),
    Mutant("nlstringkey", NL, "return positions[Key(pair: pair, key: name)]", "return nil", mode="stmt"),
    Mutant("nlnormalize", NL, ".integer(b ? 1 : 0)", "value"),
    Mutant("nlnullkey", NL, "json.kind(keyOffset) != .null", "true"),
    Mutant("nlcount", NL, "counts[pair, default: 0] &+= 1", "", mode="stmt"),
    Mutant("nlidtype", NL, "preconditionFailure(\"A node-link id must be a string or an integer, not \\(id)\")", "break", mode="stmt"),

    # Mermaid.
    Mutant("mdstylelink", MD, "next < n && _isMermaidID(text[next])", "next < n"),
    Mutant("mdbudget", MD, "try budget.spend(sources.count &* targets.count, at: link.offset)", "", mode="stmt"),
    Mutant("mdbudgetunit", MD, "budget = _ExpansionBudget(inputCount: n, perByte: 1)", "budget = _ExpansionBudget(inputCount: n, perByte: 16)", mode="stmt"),

    # Writers: distinct IDs, keys by scalars.
    Mutant("idrepeat", WS, "!repeated", "true"),
    Mutant("distinctkeys", WS, "!_sameScalars(pairs[i].key, pairs[j].key)", "pairs[i].key != pairs[j].key"),
    Mutant("scalarhash", SK, "_sameScalars(a.string, b.string)", "a.string == b.string"),

    # Decimal parsing.
    Mutant("dpdropped", DP, "if let upper = _eiselLemire(q, w &+ 1), upper == bits { return Double(bitPattern: bits | sign) }",
           "return Double(bitPattern: bits | sign)", mode="stmt"),
    Mutant("dpround", DP, "if mantissa << shift == high { mantissa &= ~1 }", "", mode="stmt"),
    Mutant("dpsubnormal", DP, "mantissa &+= mantissa & 1\n        mantissa >>= 1\n        power2 = mantissa < (1 << 52) ? 0 : 1",
           "mantissa >>= 1\n        power2 = mantissa < (1 << 52) ? 0 : 1", mode="stmt"),
    Mutant("dpsecond", DP, "high & precisionMask == precisionMask", "false"),

    # Schubfach and the layouts.
    Mutant("sftie", DF, "cmp < 0 || (cmp == 0 && s & 1 == 0) ? s : t", "cmp <= 0 ? s : t"),
    Mutant("sfshorter", DF, "if upin != wpin { return (upin ? sp10 : tp10, k) }", "", mode="stmt"),
    Mutant("sfpower2", DF, "cbl = cb &- 1\n        k = _floorLog10ThreeQuartersPow2(q)", "cbl = cb &- 2\n        k = _floorLog10Pow2(q)", mode="stmt"),
    Mutant("sfodd", DF, "c & 1", "0"),
    Mutant("sfinteger", DF, "q < 0 && q > -53", "q < 0 && q > -52"),
    Mutant("sfsticky", DF, "vbp | (((z & 0x7FFF_FFFF_FFFF_FFFF) &+ 0x7FFF_FFFF_FFFF_FFFF) >> 63)", "vbp"),
    Mutant("sfpairs", DF, "out[k &+ 1] = pairs[r &+ 1]", "out[k &+ 1] = pairs[r]", mode="stmt"),
    Mutant("sfcount", DF, "count < 19 && f >= bound", "count < 16 && f >= bound"),
    Mutant("pyexponent", DF, "e < -4 || e >= 16", "e < -4 || e >= 15"),
    Mutant("pyexpdigits", DF, "magnitude / 10 % 10", "magnitude / 10"),
    Mutant("scipyexp", DF, "d.exponent != 0", "true"),
]
