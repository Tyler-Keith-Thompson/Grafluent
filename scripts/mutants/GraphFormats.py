# Planted bugs for GraphFormats: the scanners (UTF-8, lines, XML, JSON, the shared key index), every
# reader and writer, node-link's one-pass read and GraphML's lookahead, the limits (Matrix Market's
# vertex bound, the expansion budget), the decimal parser and Schubfach, and the bulk hooks in
# AdjacencyListModule and Multigraphs the readers build through. Run with `just mutate
# GraphFormats`; see scripts/mutate.py.
#
# Not planted, being equivalent: `q > -53` → `q > -52` in Schubfach's integer shortcut (only
# q = -52 changes, i.e. [1, 2), whose one integer is 1.0, and the general path gives it the same
# shortest digits).

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
    Mutant("lexoverflow", TL, "return .double(d)", "return d.isFinite ? .double(d) : .string(\"\")", mode="stmt"),
    Mutant("listtokenws", EL, "!_containsWhitespace(bytes)", "true"),

    # Matrix Market.
    Mutant("mmlimit", MM, "if rows > vertexBound { throw ParseError(.limitExceeded, at: sizeOffset) }", "", mode="stmt"),
    Mutant("mmlimiteq", MM, "rows > vertexBound", "rows >= vertexBound"),
    Mutant("mmlimitdefault", MM, "_ExpansionBudget(inputCount: n, perByte: 16).remaining", "_ExpansionBudget(inputCount: n, perByte: 1 << 20).remaining"),
    Mutant("mmfieldcr", MM, "(c == 0x0D && (q &+ 1 == text.count || text[q &+ 1] == 0x0A))", "c == 0x0D"),
    Mutant("mmoverflow", MM, "if o1 || o2 { overflow = true }", "", mode="stmt"),
    Mutant("mmdigits", MM, "digitsOnly = false", "", mode="stmt"),
    Mutant("mmcomment", MM, "if q == lineStart && text[q] == UInt8(ascii: \"%\") { throw ParseError(.syntax, at: lineStart) }", "", mode="stmt"),
    Mutant("mmextra", MM, "if count > width { throw ParseError(.syntax, at: width == 2 ? valueStart : extra) }", "", mode="stmt"),
    Mutant("mmextrapos", MM, "width == 2 ? valueStart : extra", "extra"),
    Mutant("mmshort", MM, "if count < width { throw ParseError(.syntax, at: contentEnd) }", "", mode="stmt"),
    Mutant("mmcontentcr", MM, "if contentEnd > lineStart && text[contentEnd &- 1] == 0x0D { contentEnd &-= 1 }", "", mode="stmt"),
    Mutant("mmrange", MM, "if c < 1 || c > rows { throw ParseError(.indexOutOfRange, at: column.start) }", "", mode="stmt"),
    Mutant("mmmirror", MM, "mirrors && r != c", "mirrors", nth=0),
    Mutant("mmskew", MM, ".double(symmetry == .skewSymmetric ? -w : w)", ".double(w)"),
    Mutant("mmidentity", MM, "identity ? r &- 1 : keys[r &- 1]", "identity ? r : keys[r &- 1]", nth=0),
    Mutant("mmcount", MM, "if seen < entries { throw ParseError(.entryCountMismatch, at: n) }", "", mode="stmt"),

    # Edge and adjacency lists.
    Mutant("elcount", EL, "if line.count > width { throw ParseError(.syntax, at: line.extraStart) }", "", mode="stmt"),
    Mutant("elshort", EL, "if line.count < width { throw ParseError(.syntax, at: line.contentEnd) }", "", mode="stmt"),
    Mutant("elcolumns", EL, "value(position, k, _lexicalValue(text, s, e))", "value(position, 0, _lexicalValue(text, s, e))", mode="stmt"),
    Mutant("alhead", AL, "_ = target.insertEdge(head, resolved.key)", "_ = target.insertEdge(resolved.key, head)", mode="stmt"),
    Mutant("alline", AL, "while q < n && text[q] != 0x0A { q &+= 1 }", "", mode="stmt"),

    # Bulk target and replay.
    Mutant("bulkalias", RT, "keys[vertex] = existing\n            return (existing, false)", "return (key, false)", mode="stmt"),
    Mutant("bulkreplay", RT, "edgeAttribute(position(element), name, value)", "edgeAttribute(position(0), name, value)", mode="stmt"),
    Mutant("bulkpositions", RT, "for (edge, value) in dense.enumerated() { edgeAttribute(position(edge), name, .double(value)) }",
           "for (_, value) in dense.enumerated() { edgeAttribute(position(0), name, .double(value)) }", mode="stmt"),
    Mutant("bulkvertex", RT, "vertexAttribute(vertices[~element], name, value)", "vertexAttribute(vertices[0], name, value)", mode="stmt"),
    Mutant("bulkvertexspill", RT, "if isDense { spill() }\n        append(~key, name, value)", "append(~key, name, value)", mode="stmt"),
    Mutant("bulkdenseorder", RT, "edge == dense.count", "true", nth=0),

    # Rows built by counting sort (AdjacencyListModule, Multigraphs).
    Mutant("arcrowsoutedge", FO, "outEdgeStorage[o] = p", "outEdgeStorage[o] = o", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcrowsin", FO, "inStorage[i] = source", "inStorage[i] = target", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgerowsorder", FO, "neighborStorage[uSlot] = v", "neighborStorage[uSlot] = u", mode="stmt", module="AdjacencyListModule"),
    Mutant("distinctorient", FO, "undirected ? max(firsts[i], seconds[i]) : seconds[i]", "seconds[i]", module="AdjacencyListModule"),
    Mutant("distinctposition", FO, "positions[i] = positions[g]", "positions[i] = i", mode="stmt", module="AdjacencyListModule"),
    Mutant("parallelkey", PM, "undirected && b < a ? _SlotPair(b, a) : _SlotPair(a, b)", "_SlotPair(a, b)", module="Multigraphs"),

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
    Mutant("gmldefaultdomain", GML, "domain == .graph ? 0 : domain == .node ? 1 : 2", "domain == .graph ? 0 : 1", nth=1),
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
    Mutant("nlkeyed", NL, "if let earlier = group.keys[name] { return earlier }", "", mode="stmt"),
    Mutant("nlnewkey", NL, "while group.keys[.integer(k)] != nil { k &+= 1 }", "", mode="stmt"),
    Mutant("nlprobe", NL, "max(group.count, group.probe)", "group.probe"),
    Mutant("nlstringkey", NL, "otherKeys[us.count] = other", "", mode="stmt"),
    Mutant("nlnormalize", NL, ".integer(b ? 1 : 0)", "value"),
    Mutant("nlnullkey", NL, "json.kind(keyOffset) != .null", "true"),
    Mutant("nlcount", NL, "group.count &+= 1", "", mode="stmt"),
    Mutant("nlidtype", NL, "preconditionFailure(\"A node-link id must be a string or an integer, not \\(id)\")", "break", mode="stmt"),
    Mutant("nlnumbers", NL, "numbers[i] = earlier == i ? target.insertEdge(collected.us[i], collected.vs[i]) : numbers[earlier]",
           "numbers[i] = earlier == i ? target.insertEdge(collected.us[i], collected.vs[i]) : numbers[i]", mode="stmt"),
    Mutant("nlwriterkeycache", NL, "encodedKey.removeAll(keepingCapacity: true)", "", mode="stmt"),
    Mutant("nlwriterkeykind", NL, "lastKeyIsNode == node", "true"),
    Mutant("nlwriterkeys", NL, "out.appendDecimal(Int(keys[edge]))", "", mode="stmt"),

    # Node-link JSON, the one-pass read.
    Mutant("nl1order", NL, "guard member > last, colon() else { return false }", "guard colon() else { return false }", mode="stmt"),
    Mutant("nl1directed", NL, "guard isDirected == Direction.isDirected, readNodes() else { return false }", "guard readNodes() else { return false }", mode="stmt"),
    Mutant("nl1edges", NL, "guard text[p] == UInt8(ascii: \"}\"), last == 4 else { return false }", "guard text[p] == UInt8(ascii: \"}\") else { return false }", mode="stmt"),
    Mutant("nl1trailing", NL, "after < n", "false"),
    Mutant("nl1trailingat", NL, "ParseError(.syntax, at: trailing)", "ParseError(.syntax, at: trailing &+ 1)"),
    Mutant("nl1graphscalars", NL, "guard scalars else { return false }", "", mode="stmt"),
    Mutant("nl1member", NL, "if memberWords[k] == word { return false }", "", mode="stmt"),
    Mutant("nl1longmember", NL, "if same { return false }", "", mode="stmt"),
    Mutant("nl1memberlimit", NL, "guard memberCount < Self.memberLimit else { return false }", "", mode="stmt"),
    Mutant("nl1digits", NL, "guard q &- digits <= 18 else { return nil }", "", mode="stmt"),
    Mutant("nl1finite", NL, "!integral && d.isFinite", "!integral"),
    Mutant("nl1dupinteger", NL, "guard dense[i] == 0 else { return false }", "", mode="stmt"),
    Mutant("nl1dupstring", NL, "guard added else { return false }", "", mode="stmt"),
    Mutant("nl1merge", NL, "if !target.key(for: vertex).inserted { throw ParseError(.duplicateVertex, at: idOffsets[k]) }", "_ = target.key(for: vertex)", mode="stmt"),
    Mutant("nl1vertexattributes", NL, "vertexAttributes.elements[entry] == ~k", "true"),
    Mutant("nl1graph", NL, "if let scalar = json.scalar(value, scratch: &scratch) { graphAttribute(_string(name), scalar) }", "", mode="stmt"),

    # GraphML, the lookahead.
    Mutant("gmllookkey", GML, "collector.sink.active = false\n                return", "return", mode="stmt"),
    Mutant("gmllookbudget", GML, "if graphDefaults > 0 { try budget.spend(graphDefaults, at: 0) }", "", mode="stmt"),
    Mutant("gmllookport", GML, "node.unsupported == nil", "true", nth=1),
    Mutant("gmllookdup", GML, "guard ids.insertIfAbsent(id, hash: _IDTable.hash(id)) else { return false }", "_ = ids.insertIfAbsent(id, hash: _IDTable.hash(id))", mode="stmt"),
    Mutant("gmllooktarget", GML, "ids.find(end, hash: _IDTable.hash(end))", "ids.find(source, hash: _IDTable.hash(source))"),
    Mutant("gmllookdefault", GML, "value.start == Int.min", "false"),
    Mutant("gmllookvertex", GML, "buffer.recordVertex(~value.element, value.key, attribute)", "", mode="stmt"),
    Mutant("gmllookview", GML, "spans.append(base - start)", "spans.append(0)", mode="stmt"),
    Mutant("gmllookdirected", GML, "directed.withBytes({ _xmlBoolean(Array($0)) }) != Direction.isDirected", "false"),
    Mutant("gmllookmerge", GML, "if !lookahead.key(for: vertex).inserted { throw ParseError(.duplicateVertex, at: offset) }", "_ = lookahead.key(for: vertex)", mode="stmt"),
    Mutant("gmllookoffset", GML, "ParseError(.invalidVertex, at: offset)", "ParseError(.invalidVertex, at: 0)"),
    Mutant("gmledgeport", GML, "edge.sourcePort = a.nameStart", "", mode="stmt"),
    Mutant("gmledgedirected", GML, "if scanner.isNamed(a, \"directed\") { directed = a }", "", mode="stmt"),
    Mutant("gmlverbatim", GML, "a.verbatim", "true"),
    Mutant("gmlnegativezero", GML, "i != 0", "true"),
    Mutant("gmltextview", GML, "base >= start && base + bytes.count <= start + input.count", "true"),
    Mutant("gmltextpieces", GML, "element.text.append(contentsOf: view)", "", mode="stmt"),
    Mutant("xmltextdirect", XML, "observer.text(UnsafeBufferPointer(rebasing: text[p ..< q]), depth: depth)",
           "observer.text(UnsafeBufferPointer(rebasing: text[p ..< max(p, q &- 1)]), depth: depth)", mode="stmt"),
    Mutant("xmlattributeclear", XML, "while !attributes.isEmpty { attributes.removeLast() }", "if !attributes.isEmpty { attributes.removeLast() }", mode="stmt"),
    Mutant("mdgroupclear", MD, "if list.count == 1 { list.removeLast() } else if !list.isEmpty { list.removeAll(keepingCapacity: true) }",
           "if list.count == 1 { list.removeLast() }", mode="stmt"),

    # Mermaid.
    Mutant("mdstylelink", MD, "next < n && _isMermaidID(text[next])", "next < n"),
    Mutant("mdbudget", MD, "try budget.spend(sources.count &* targets.count, at: link.offset)", "", mode="stmt"),
    Mutant("mdbudgetunit", MD, "budget = _ExpansionBudget(inputCount: n, perByte: 1)", "budget = _ExpansionBudget(inputCount: n, perByte: 16)", mode="stmt"),

    # Writers: distinct IDs, keys by scalars.
    Mutant("idrepeat", WS, "!repeated", "true"),
    Mutant("distinctkeys", WS, "!_sameScalars(key, other)", "key != other"),
    Mutant("iddecimalzero", WS, "(count == 1 || bytes[0] != UInt8(ascii: \"0\"))", "true"),
    Mutant("iddecimallimit", WS, "return value < decimalLimit ? value : nil", "return value", mode="stmt"),
    Mutant("idword", WS, "if n <= 8 && out.appendWord(word, count: n) { return }", "if out.appendWord(word, count: n) { return }", mode="stmt"),
    Mutant("outword", OB, "UInt(bitPattern: remaining &- 8) <= 8", "remaining <= 16"),
    Mutant("outdigit", OB, "UInt(bitPattern: value) < 10", "value < 10"),
    Mutant("idseparator", WS, "word << 8 | UInt64(separator)", "word << 8"),
    Mutant("distinctmany", WS, "precondition(set.insert(_ScalarKey(key)).inserted, \"Attribute key \\(key) given twice for one element\")", "_ = set.insert(_ScalarKey(key))", mode="stmt"),
    Mutant("listtokenplain", EL, "b <= 0x20 || b >= 0x7F", "b < 0x20 || b >= 0x7F"),
    Mutant("nlwritermulti", NL, "multigraph = true", "", mode="stmt"),
    Mutant("nlwriterkeyreset", NL, "counts[b] = 0", "", mode="stmt"),
    Mutant("dpeightlimit", DP, "significant <= 11", "significant <= 12", nth=1),
    Mutant("dpeightcheck", DP, "(word & 0xF0F0_F0F0_F0F0_F0F0)", "(0x3030_3030_3030_3030)"),
    Mutant("scalarhash", SK, "_sameScalars(a.string, b.string)", "a.string == b.string"),

    # Decimal parsing.
    Mutant("dpdropped", DP, "if let upper = _eiselLemire(q, w &+ 1), upper == bits { return Double(bitPattern: bits | sign) }",
           "return Double(bitPattern: bits | sign)", mode="stmt"),
    Mutant("dpround", DP, "if mantissa << shift == high { mantissa &= ~1 }", "", mode="stmt"),
    Mutant("dpsubnormal", DP, "mantissa &+= mantissa & 1\n        mantissa >>= 1\n        power2 = mantissa < (1 << 52) ? 0 : 1",
           "mantissa >>= 1\n        power2 = mantissa < (1 << 52) ? 0 : 1", mode="stmt"),
    Mutant("dpsecond", DP, "high & precisionMask == precisionMask", "false"),
    Mutant("dplongcut", DP, "end &- start <= 700", "true"),
    Mutant("dpsticky", DP, "if sticky { digits.append(UInt8(ascii: \"1\")) }", "", mode="stmt"),

    # Schubfach and the layouts.
    Mutant("sftie", DF, "cmp < 0 || (cmp == 0 && s & 1 == 0) ? s : t", "cmp <= 0 ? s : t"),
    Mutant("sfshorter", DF, "if upin != wpin { return (upin ? sp10 : tp10, k) }", "", mode="stmt"),
    Mutant("sfpower2", DF, "cbl = cb &- 1\n        k = _floorLog10ThreeQuartersPow2(q)", "cbl = cb &- 2\n        k = _floorLog10Pow2(q)", mode="stmt"),
    Mutant("sfodd", DF, "c & 1", "0"),
    Mutant("sfsticky", DF, "vbp | (((z & 0x7FFF_FFFF_FFFF_FFFF) &+ 0x7FFF_FFFF_FFFF_FFFF) >> 63)", "vbp"),
    Mutant("sfpairs", DF, "out[k &+ 1] = pairs[r &+ 1]", "out[k &+ 1] = pairs[r]", mode="stmt"),
    Mutant("pyexponent", DF, "e < -4 || e >= 16", "e < -4 || e >= 15"),
    Mutant("pyexpdigits", DF, "magnitude / 10 % 10", "magnitude / 10"),
    Mutant("scipyexp", DF, "d.exponent != 0", "true"),
    Mutant("sftwodigit", DF, "s >= 10", "s >= 100"),
]
