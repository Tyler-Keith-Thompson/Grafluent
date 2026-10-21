# Planted bugs for GraphFormats (GML, Pajek, the nauty formats, DIMACS, METIS, Cytoscape JSON, GEXF, LEDA and
# delimited and dict edge lists included): the scanners (UTF-8, lines, XML, JSON, the shared key index), every
# reader and writer, node-link's one-pass read and GraphML's lookahead, the limits (Matrix Market's
# vertex bound, the expansion budget), the decimal parser and Schubfach, and the bulk hooks in
# AdjacencyListModule and Multigraphs the readers build through. Run with `just mutate
# GraphFormats`; see scripts/mutate.py.
#
# Not planted, being equivalent: `q > -53` → `q > -52` in Schubfach's integer shortcut (only
# q = -52 changes, i.e. [1, 2), whose one integer is 1.0, and the general path gives it the same
# shortest digits). `if x >= n || v >= n { break }` → `if v >= n { break }` in the sparse6
# reader: with v < n ≤ x the next step sets v = x ≥ n, after which no unit adds an edge (nauty's
# own reader goes on that way), so stopping or not reads the same graph. In the Cytoscape edge
# pass, counting a multigraph's `key` as an attribute only marks the edge for the reporting pass,
# which skips `key` itself: the same calls either way. In the plain Pajek edge-line path a quote,
# apostrophe or backslash makes the field fail `_fastDecimal` anyway, and a `-` before an unsigned
# field gives a value below 1 that fails the range check, so both lines go to the general reading
# either way.

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
IL = "IntegerLists.swift"
NA = "Nauty.swift"
DI = "DIMACS.swift"
ME = "METIS.swift"
GF = "GML.swift"
PJ = "Pajek.swift"
CY = "CytoscapeJSON.swift"
PY = "PythonLiterals.swift"
GX = "GEXF.swift"
LD = "LEDA.swift"

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
    Mutant("elcount", EL, "if count > width && !dict { throw ParseError(.syntax, at: extraStart) }", "", mode="stmt"),
    Mutant("elshort", EL, "if count < width { throw ParseError(.syntax, at: contentEnd) }", "", mode="stmt"),
    Mutant("elcolumns", EL, "buffer.record(position, k, _lexicalValue(text, s, e))", "buffer.record(position, 0, _lexicalValue(text, s, e))", mode="stmt"),
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
    Mutant("dotdefaultplace", DOT, "pairs[place].1 = value", "pairs.append((key, value))", mode="stmt"),
    Mutant("dotdefaultscalar", DOT, "index[_ScalarKey(key)]", "pairs.firstIndex(where: { $0.0 == key })", nth=0),
    Mutant("dotbudgetvertex", DOT, "try budget.spend(defaults.count, at: statement)", "", mode="stmt"),
    Mutant("dotbudgetedge", DOT, "try budget.spend(perEdge &+ edgeDefaults.pairs.count &+ ports &+ pairs.count, at: statement)",
           "try budget.spend(perEdge &+ edgeDefaults.pairs.count, at: statement)", mode="stmt"),
    Mutant("dotidcheck", DOT, "try ids.set(k) { _appendDOTID(id, to: &$0) }",
           "try ids.set(k) { _appendDOTID(id + \"\\(k)\", to: &$0) }", mode="stmt"),

    # The expansion budget.
    Mutant("budgetfloor", EB, "remaining = overflow || product > Int.max - 4096 ? .max : product + 4096", "remaining = overflow ? .max : product &+ 1_000_000_000", mode="stmt"),
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
    Mutant("nl1digits", NL, "guard q &- digits <= (Int.bitWidth == 64 ? 18 : 9) else { return nil }", "", mode="stmt"),
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
    Mutant("mdbudget", MD, "try budget.spend(links, at: link.offset)", "", mode="stmt"),
    Mutant("mdbudgetunit", MD, "budget = _ExpansionBudget(inputCount: n, perByte: 1)", "budget = _ExpansionBudget(inputCount: n, perByte: 16)", mode="stmt"),

    # Writers: distinct IDs, keys by scalars.
    Mutant("idrepeat", WS, "if repeated { throw .duplicateID }", "", mode="stmt"),
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

    # Write errors: each check, and the held output of the writers that check as they write.
    Mutant("heldoutput", OB, "pieces.append(piece)", "output.write(piece)"),
    Mutant("elidtoken", EL, "if !_appendListToken(id, delimiter: delimiter, to: &bytes) { throw .invalidID }", "_ = _appendListToken(id, delimiter: delimiter, to: &bytes)", mode="stmt"),
    Mutant("elvaluetoken", EL, "if !_appendListToken(s, delimiter: delimiter, to: &scratch) { throw .invalidValue }", "_ = _appendListToken(s, delimiter: delimiter, to: &scratch)", mode="stmt"),
    Mutant("elboolean", EL, "throw .invalidValue", "out.appendASCII(\"True\")", mode="stmt", nth=1),
    Mutant("alidtoken", AL, "if !_appendListToken(id, delimiter: nil, to: &bytes) { throw .invalidID }", "_ = _appendListToken(id, delimiter: nil, to: &bytes)", mode="stmt"),
    Mutant("gmlvaluexml", GML, "if !_isXMLRepresentable(s) { throw .invalidValue }", "", mode="stmt"),
    Mutant("gmlkeyxml", GML, "if !_isXMLRepresentable(pair.key) { throw .invalidKey }", "", mode="stmt"),
    Mutant("gmlidxml", GML, "_isXMLRepresentable(id)", "true"),
    Mutant("gmltypeold", GML, "(old == .long || old == .double)", "true"),
    Mutant("gmltypenew", GML, "(type == .long || type == .double)", "true"),
    Mutant("nlfinite", NL, "if !d.isFinite { throw .invalidValue }", "", mode="stmt"),
    Mutant("nlreservedid", NL, "_sameScalars(key, ascii: \"id\")", "false"),
    Mutant("nlreservedendpoint", NL, "_isEndpointKey(key)", "false"),
    Mutant("mdidempty", MD, "!id.isEmpty", "true"),
    Mutant("mdidbytes", MD, "id.utf8.allSatisfy(_isMermaidID)", "true"),
    Mutant("mdidreserved", MD, "!_reservedMermaidIDs.contains(id)", "true"),
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
    # Shared helpers of the readers that insert a declared vertex count.
    Mutant("vertexbounddefault", RT, "_ExpansionBudget(inputCount: inputCount, perByte: 16).remaining", "_ExpansionBudget(inputCount: inputCount, perByte: 1 << 20).remaining"),
    Mutant("indexidentity", RT, "keys.append(identity ? target.appendDistinct(vertex) : target.key(for: vertex).key)", "keys.append(target.appendDistinct(vertex))", mode="stmt"),

    # graph6, sparse6, digraph6.
    Mutant("nautyheader", NA, "return matches ? k : 0", "return 0", mode="stmt"),
    Mutant("nautysizeshort", NA, "if first < 126 { return (Int(first &- 63), p &+ 1) }", "if first <= 126 { return (Int(first &- 63), p &+ 1) }", mode="stmt"),
    Mutant("nautysizewide", NA, "text[q] == 126", "false"),
    Mutant("nautyextra", NA, "q &- p == limit || !_isNautyByte(text[q])", "!_isNautyByte(text[q])"),
    Mutant("nautyshort", NA, "if end &- dataStart < needed { throw ParseError(.unexpectedEndOfInput, at: end) }", "", mode="stmt"),
    Mutant("nautypadding", NA, "if needed > 0 && (text[end &- 1] &- 63) & UInt8((1 << padding) &- 1) != 0 { throw ParseError(.invalidValue, at: end &- 1) }", "", mode="stmt"),
    Mutant("nautytrailing", NA, "if q < count { throw ParseError(.syntax, at: q) }", "", mode="stmt"),
    Mutant("nautycrlf", NA, "lineFeed > p && text[lineFeed &- 1] == 0x0D", "false"),
    Mutant("nautycolumn", NA, "i == j", "i > j"),
    Mutant("nautyrow", NA, "j == n", "j > n"),
    Mutant("sparse6width", NA, "n <= 1 ? 0 : Int.bitWidth &- (n &- 1).leadingZeroBitCount", "n <= 1 ? 1 : Int.bitWidth &- (n &- 1).leadingZeroBitCount"),
    Mutant("sparse6orient", NA, "_ = target.insertEdge(keys[x], keys[v])", "_ = target.insertEdge(keys[v], keys[x])", mode="stmt"),
    Mutant("sparse6limit", NA, "if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: sizeOffset) }", "", mode="stmt"),
    Mutant("sparse6incremental", NA, "if text[p] == UInt8(ascii: \";\") { throw ParseError(.unsupported, at: p) }", "", mode="stmt"),
    Mutant("nautyloop", NA, "if u == v { throw .selfLoop }", "", mode="stmt"),
    Mutant("nautyparallel", NA, "if data[byte] & mask != 0 { throw .parallelEdge }", "", mode="stmt"),
    Mutant("sparse6pad", NA, "k >= width &+ 1 && last == n &- 2 && n == 1 << width", "false"),
    Mutant("sparse6skip", NA, "j > last &+ 1", "j > last &+ 2"),
    Mutant("nautysizeeight", NA, "n > 258_047", "n > 262_143"),

    # DIMACS.
    Mutant("dimacscomment", DI, "if e0 &- s0 == 1 && text[s0] == UInt8(ascii: \"c\") { continue }", "", mode="stmt"),
    Mutant("dimacskind", DI, "if shortestPath != directed { throw ParseError(.kindMismatch, at: s) }", "", mode="stmt"),
    Mutant("dimacsmany", DI, "if seen == m { throw ParseError(.entryCountMismatch, at: s0) }", "", mode="stmt"),
    Mutant("dimacsfew", DI, "if seen < m { throw ParseError(.entryCountMismatch, at: text.count) }", "", mode="stmt"),
    Mutant("dimacsindex", DI, "if value < 1 || value > n { throw ParseError(.indexOutOfRange, at: field.0) }", "if value < 1 || value > n &+ 1 { throw ParseError(.indexOutOfRange, at: field.0) }", mode="stmt"),
    Mutant("dimacsweight", DI, "if directed { weight(edge, w) }", "", mode="stmt"),
    Mutant("dimacswidth", DI, "width = letter == UInt8(ascii: \"a\") ? 4 : 3", "width = 4", mode="stmt"),
    Mutant("dimacslimit", DI, "if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: fields[2].0) }", "", mode="stmt"),
    Mutant("dimacsflow", DI, "_matches(text, s, e, \"max\")", "false"),
    Mutant("dimacswriteweight", DI, "out.appendDecimal(weight(position))", "out.appendDecimal(0)", mode="stmt"),

    # METIS.
    Mutant("metisfmt", ME, "if place == 0 { hasEdgeWeight = true } else if place == 1 { hasVertexWeight = true } else { hasSize = true }",
           "if place == 1 { hasEdgeWeight = true } else if place == 0 { hasVertexWeight = true } else { hasSize = true }", mode="stmt"),
    Mutant("metisncon", ME, "if ncon > 1 { throw ParseError(.unsupported, at: s) }", "", mode="stmt"),
    Mutant("metisloop", ME, "if v == u { throw ParseError(.invalidValue, at: field.0) }", "", mode="stmt"),
    Mutant("metismirror", ME, "unmirrored = field.0", "", mode="stmt"),
    Mutant("metisunconsumed", ME, "unmirrored ?? mirrors.firstUnconsumed()", "unmirrored"),
    Mutant("metiscount", ME, "if later != m { throw ParseError(.entryCountMismatch, at: edgeCountOffset) }", "", mode="stmt"),
    Mutant("metisweight", ME, "!consumed[k] && weight[k] == w", "!consumed[k]"),
    Mutant("metissort", ME, "!sorted", "false"),
    Mutant("metisorder", ME, "order[k] < best", "order[k] > best"),
    Mutant("metistrailing", ME, "if q < line.end { throw ParseError(.syntax, at: q) }", "", mode="stmt"),
    Mutant("metiscomment", ME, "if line.end > line.start && text[line.start] == UInt8(ascii: \"%\") { continue }", "", mode="stmt", nth=1),
    Mutant("metissize", ME, "buffer.recordVertex(keys[u], 1, .integer(try _integerValue(text, field)))", "buffer.recordVertex(keys[u], 0, .integer(try _integerValue(text, field)))", mode="stmt"),
    Mutant("metiswriterrepeat", ME, "if stamp[far[k]] == u { firstRepeat = min(firstRepeat, edge[k]) }", "", mode="stmt"),
    Mutant("metiswriterloop", ME, "if firstLoop < firstRepeat { throw .selfLoop }", "", mode="stmt"),
    Mutant("metiswriterheader", ME, "out.appendASCII(hasWeight ? \" 1\\n\" : \"\\n\")", "out.appendASCII(\"\\n\")", mode="stmt"),

    # GML.
    Mutant("gmlcomment", GF, "c == UInt8(ascii: \"#\")", "false"),
    Mutant("gmlinf", GF, "if isKey(word, \"INF\") { return (.double(.infinity), start) }", "", mode="stmt"),
    Mutant("gmlintegral", GF, "if integral { throw ParseError(.numberOutOfRange, at: start) }", "", mode="stmt"),
    Mutant("gmlboundary", GF, "if p < n && _isGMLKeyByte(text[p]) { throw ParseError(.syntax, at: p) }", "", mode="stmt"),
    Mutant("gmldepth", GF, "if depth > 64 { throw ParseError(.nestingTooDeep, at: open) }", "if depth > 65 { throw ParseError(.nestingTooDeep, at: open) }", mode="stmt"),
    Mutant("gmlsecond", GF, "if graphSeen { throw ParseError(.unsupported, at: name.lowerBound) }", "", mode="stmt"),
    Mutant("gmlnograph", GF, "if !graphSeen { throw ParseError(.unexpectedEndOfInput, at: n) }", "", mode="stmt"),
    Mutant("gmldirected", GF, "if directed && (flag == 1) != Direction.isDirected { throw ParseError(.kindMismatch, at: offset) }", "", mode="stmt"),
    Mutant("gmlmissingdirected", GF, "if Direction.isDirected && !directedSeen { throw ParseError(.kindMismatch, at: graphOffset) }", "", mode="stmt"),
    Mutant("gmlundeclared", GF, "ids[targets[k]]", "ids[sources[k]]"),
    Mutant("gmldupid", GF, "if ids[id] != nil { throw ParseError(.duplicateVertex, at: idOffset) }", "", mode="stmt"),
    Mutant("gmlname", GF, "map(label.map(AttributeValue.string) ?? .integer(id))", "map(.integer(id))"),
    Mutant("gmllabeltext", GF, "label = _string(UnsafeBufferPointer(rebasing: text[offset ..< p]))", "label = \"\"", mode="stmt"),
    Mutant("gmlids", GF, "return id < dense.count && dense[id] != 0 ? dense[id] &- 1 : nil", "return id < dense.count && dense[id] != 0 ? dense[id] : nil", mode="stmt"),
    Mutant("gmlamp", GF, "decoded = \"&\"", "decoded = nil", mode="stmt"),
    Mutant("gmlhex", GF, "k < end && text[k] == UInt8(ascii: \"x\")", "false"),
    Mutant("gmlclamp", GF, "min(value &* (hex ? 16 : 10) &+ digit, 0x110000)", "value &* (hex ? 16 : 10) &+ digit"),
    Mutant("gmlwideint", GF, "Int64(i) >= -(1 << 31) && Int64(i) < 1 << 31", "true"),
    Mutant("gmldot", GF, "if !dot { out.append(UInt8(ascii: \".\")) }", "", mode="stmt"),
    Mutant("gmlinfwrite", GF, "out.appendASCII(d < 0 ? \"-INF\" : \"+INF\")", "out.appendASCII(d < 0 ? \"-INF\" : \"INF\")", mode="stmt"),
    Mutant("gmlescape", GF, "v >= 0x20 && v <= 0x7E && v != 0x22 && v != 0x26", "v >= 0x20 && v <= 0x7E && v != 0x22"),
    Mutant("gmlinvalidkey", GF, "guard _isGMLKey(key) else { throw .invalidKey }", "", mode="stmt"),
    Mutant("gmlreserved", GF, "for word in reserved where _sameScalars(key, ascii: word) { throw .reservedKey }", "", mode="stmt"),
    Mutant("gmlmultigraph", GF, "if _parallelEdgeKeys(source) != nil { out.appendASCII(\"  multigraph 1\\n\") }", "", mode="stmt"),

    # Pajek.
    Mutant("pajekdquote", PJ, "if e != UInt8(ascii: \"\\\"\") && e != UInt8(ascii: \"\\\\\") { bytes.append(d) }", "", mode="stmt"),
    Mutant("pajekescape", PJ, "bytes.append(text[q &+ 1])\n                    q &+= 2", "bytes.append(c)\n                    q &+= 2", mode="stmt"),
    Mutant("pajeksquote", PJ, "c == UInt8(ascii: \"'\") || c == UInt8(ascii: \"\\\"\")", "c == UInt8(ascii: \"\\\"\")"),
    Mutant("pajekcomment", PJ, "if q == line.end || text[q] == UInt8(ascii: \"%\") { continue }", "if q == line.end { continue }", mode="stmt"),
    Mutant("pajekkind", PJ, "if arcs != Direction.isDirected { throw ParseError(.kindMismatch, at: q) }", "", mode="stmt"),
    Mutant("pajeknetwork", PJ, "graphAttribute(\"name\", .string(_string(UnsafeBufferPointer(rebasing: text[s ..< t]))))", "", mode="stmt"),
    Mutant("pajekdup", PJ, "if listed[k] { throw ParseError(.duplicateVertex, at: words.offsets[0]) }", "", mode="stmt"),
    Mutant("pajeklabeldefault", PJ, "labels.append(contentsOf: String(k &+ 1).utf8)", "labels.append(contentsOf: String(k).utf8)", mode="stmt"),
    Mutant("pajekunlisted", PJ, "scratch.append(contentsOf: String(k &+ 1).utf8)", "scratch.append(contentsOf: String(k).utf8)", mode="stmt"),
    Mutant("pajekxy", PJ, "f == 4 ? .string(words.string(f)) : .double(try words.real(f))", ".string(words.string(f))"),
    Mutant("pajekpair", PJ, "guard f &+ 1 < words.count else { throw ParseError(.syntax, at: words.offsets[f]) }", "if f &+ 1 >= words.count { break }", mode="stmt", nth=0),
    Mutant("pajekweight", PJ, "if let weight { buffer.record(edge, 0, .double(weight)) }", "", mode="stmt", nth=1),
    Mutant("pajekfastnoweight", PJ, "if let weight { buffer.record(edge, 0, .double(weight)) }", "", mode="stmt", nth=0),
    Mutant("pajeklist", PJ, "1 ..< max(1, words.count)", "2 ..< max(2, words.count)"),
    Mutant("pajeklimit", PJ, "if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: countOffset) }", "", mode="stmt"),
    Mutant("pajeksecond", PJ, "if verticesSeen { throw ParseError(.unsupported, at: q) }", "", mode="stmt"),
    Mutant("pajeklistkind", PJ, "section = list ? .edgeLists : .edges", "section = .edges", mode="stmt"),
    Mutant("pajekapostrophe", PJ, "b == UInt8(ascii: \"\\\"\") || b == UInt8(ascii: \"'\") || b == UInt8(ascii: \"\\\\\")", "b == UInt8(ascii: \"\\\"\") || b == UInt8(ascii: \"\\\\\")"),
    Mutant("pajekescapewrite", PJ, "sink.append(UInt8(ascii: \"\\\\\"))\n            run = k", "run = k", mode="stmt"),
    Mutant("pajekskipshape", PJ, "_sameScalars($0, ascii: \"x\") || _sameScalars($0, ascii: \"y\") || _sameScalars($0, ascii: \"shape\")",
           "_sameScalars($0, ascii: \"x\") || _sameScalars($0, ascii: \"y\")"),
    Mutant("pajeklinefeed", PJ, "for b in bytes where b == 0x0A { return false }", "", mode="stmt"),

    # Cytoscape JSON.
    Mutant("cykind", CY, "if isDirected != Direction.isDirected { throw ParseError(.kindMismatch, at: directed ?? top) }", "", mode="stmt"),
    Mutant("cypairs", CY, "guard items.count == 2, json.kind(items[0]) == .string else { throw ParseError(.invalidValue, at: pair) }", "guard items.count >= 2 else { throw ParseError(.invalidValue, at: pair) }", mode="stmt"),
    Mutant("cygroup", CY, "guard isNodes || isEdge else { throw ParseError(.invalidValue, at: group) }", "", mode="stmt"),
    Mutant("cyinferedge", CY, "isEdge = _jsonMember(json, data, \"source\", key: &key) != nil", "isEdge = false", mode="stmt"),
    Mutant("cydup", CY, "if registry.find(bytes) != nil { throw ParseError(.duplicateVertex, at: idOffset) }", "", mode="stmt"),
    Mutant("cyintid", CY, "self[keyPath: buffer].append(contentsOf: String(i).utf8)", "self[keyPath: buffer].append(contentsOf: String(i &+ 1).utf8)", mode="stmt"),
    Mutant("cy1intid", CY, "arena.append(contentsOf: String(i).utf8)", "arena.append(contentsOf: String(i &+ 1).utf8)", mode="stmt"),
    Mutant("cyunsupported", CY, "unsupported = value", "", mode="stmt", nth=1),
    Mutant("cynodeunsupported", CY, "unsupported = value", "", mode="stmt", nth=0),
    Mutant("cyvalue", CY, "!hasValue", "true"),
    Mutant("cyname", CY, "!hasName", "true"),
    Mutant("cyreserved", CY, "if _sameScalars(key, ascii: \"id\") { throw .reservedKey }", "", mode="stmt"),
    Mutant("cykeys", CY, "out.appendDecimal(Int(keys[edge]))", "out.appendDecimal(0)", mode="stmt"),

    # Edge list: delimiters and dict data.
    Mutant("dictdetect", EL, "count > width && columnCount == 0 && extraStart < contentEnd && text[extraStart] == UInt8(ascii: \"{\")", "false"),
    Mutant("dictdetectint", IL, "count > width && columnCount == 0 && extraStart < contentEnd && text[extraStart] == UInt8(ascii: \"{\")", "false"),
    Mutant("dicttail", EL, "if q < end && text[q] != UInt8(ascii: \"#\") { throw ParseError(.syntax, at: q) }", "", mode="stmt"),
    Mutant("delimblank", EL, "isBlank = k >= end", "isBlank = false", mode="stmt"),
    Mutant("delimcr", EL, "if end == lineEnd && end > p && text[end &- 1] == 0x0D { end &-= 1 }", "", mode="stmt"),
    Mutant("delimcolumn", EL, "while e < contentEnd && text[e] != delimiter { e &+= 1 }", "while e < contentEnd { e &+= 1 }", mode="stmt", nth=0),
    Mutant("delimintcolumn", IL, "values.append(.integer(i))", "values.append(.double(Double(i)))", mode="stmt", nth=0),
    Mutant("delimseparator", EL, "out.append(separator)", "out.append(0x20)", mode="stmt", nth=0),
    Mutant("delimtoken", EL, "b == delimiter || b == UInt8(ascii: \"#\") || b == 0x0A || b == 0x0D", "b == UInt8(ascii: \"#\") || b == 0x0A || b == 0x0D"),
    Mutant("delimascii", EL, "precondition(v < 0x80, \"An edge-list delimiter must be ASCII\")", "", mode="stmt"),
    Mutant("pyquotes", PY, "simple = e", "simple = 0x5C", mode="stmt"),
    Mutant("pyhexwidth", PY, "e == UInt8(ascii: \"u\") ? 4 : 8", "4"),
    Mutant("pyoctal", PY, "k < q &+ 4", "k < q &+ 3"),
    Mutant("pyunknown", PY, "out.append(UInt8(ascii: \"\\\\\"))\n            q &+= 1", "q &+= 1", mode="stmt"),
    Mutant("pysurrogate", PY, "Unicode.Scalar(scalar)", "Unicode.Scalar(scalar > 0x10FFFF ? 0x41 : scalar)"),
    Mutant("pytrue", PY, "if _matches(text, q, e, \"True\") { return (.boolean(true), e) }", "", mode="stmt"),
    Mutant("pynone", PY, "if _matches(text, q, e, \"None\") { throw ParseError(.unsupported, at: q) }", "", mode="stmt"),
    Mutant("pyminusinf", PY, "if _matches(text, q, e, \"-inf\") { return (.double(-.infinity), e) }", "", mode="stmt"),
    Mutant("pyintegral", PY, "if integral { throw ParseError(.numberOutOfRange, at: q) }", "", mode="stmt"),
    Mutant("pytrailingcomma", PY, "if q < end && text[q] == UInt8(ascii: \"}\") { return q &+ 1 }", "", mode="stmt", nth=1),
    Mutant("pykey", PY, "if _startsPythonValue(c) { throw ParseError(.unsupported, at: q) }", "", mode="stmt"),

    # DOT subgraphs and ports.
    Mutant("dotsubdepth", DOT, "if scopes.count > 64 { throw ParseError(.nestingTooDeep, at: open.start) }", "if scopes.count > 65 { throw ParseError(.nestingTooDeep, at: open.start) }", mode="stmt"),
    Mutant("dotsubgraphattr", DOT, "if root { graphAttribute(k, .string(v)) }", "graphAttribute(k, .string(v))", mode="stmt"),
    Mutant("dotsubgraphassign", DOT, "if root { graphAttribute(key, .string(value)) }", "graphAttribute(key, .string(value))", mode="stmt"),
    Mutant("dottailport", DOT, "if let tailPort { edgeAttribute(position, \"tailport\", .string(tailPort)) }", "", mode="stmt"),
    Mutant("dotcompass", DOT, "port += \":\" + (try identifierString())", "_ = try identifierString()", mode="stmt"),
    Mutant("dotproduct", DOT, "suspended.operands.append((order, nil))", "suspended.operands.append((Array(order.prefix(1)), nil))", mode="stmt"),
    Mutant("dotsubgraphref", DOT, "guard isPunctuation(peek, \"{\") else { throw ParseError(.unsupported, at: keyword.start) }", "guard isPunctuation(peek, \"{\") else { throw ParseError(.syntax, at: keyword.start) }", mode="stmt"),
    Mutant("dotperedge", DOT, "tails.count == 1 && heads.count == 1 ? 0 : 1", "0"),

    # GraphML nested graphs, node-link array ids.
    Mutant("gmlnestedkind", GML, "if isDirected != Sink.isDirected { throw ParseError(.unsupported, at: tag.offset) }", "", mode="stmt"),
    Mutant("gmlnestedafter", GML, "if isData || scanner.isLocal(tag, \"port\") { throw ParseError(.unsupported, at: tag.offset) }", "", mode="stmt"),
    Mutant("gmlnestedback", GML, "inHandedNode = true", "inHandedNode = false", mode="stmt"),
    Mutant("nlarrayobject", NL, "throw ParseError(.invalidValue, at: id)", "out.appendASCII(\"{}\")", mode="stmt"),
    Mutant("nlarrayseparator", NL, "if !first { out.appendASCII(\", \") }", "if !first { out.appendASCII(\",\") }", mode="stmt"),
    Mutant("nlarraynull", NL, "out.appendASCII(\"null\")", "", mode="stmt"),
    # Cytoscape JSON's one pass, and the fast paths of Pajek, METIS and DIMACS fields.
    Mutant("cy1multikey", CY, "guard multigraphKnown == true, scalar() != nil else { return false }", "guard scalar() != nil else { return false }", mode="stmt"),
    Mutant("cy1rawcontrol", CY, "!raw.contains(where: { text[$0] < 0x20 })", "true"),
    Mutant("cy1end", CY, "return p == n", "return true", mode="stmt"),
    Mutant("cy1sourcefirst", CY, "guard hasSource, noteID(node: false) else { return false }", "guard noteID(node: false) else { return false }", mode="stmt"),
    Mutant("pajekfastweight", PJ, "weight = d", "weight = -d", mode="stmt"),
    Mutant("metisfastrange", ME, "value >= 1 && value <= n", "value >= 1 && value <= n &+ 1"),

    # GEXF: the one walk, its checks, the defaults, and the writer.
    Mutant("gexfroot", GX, 'guard scanner.isLocal(tag, "gexf") else { throw ParseError(.syntax, at: tag.offset) }', "", mode="stmt"),
    Mutant("gexfsecondgraph", GX, "if graphOffset != nil { throw ParseError(.unsupported, at: tag.offset) }", "", mode="stmt"),
    Mutant("gexfkind", GX, "if isDirected != Direction.isDirected { throw ParseError(.kindMismatch, at: tag.offset) }", "", mode="stmt"),
    Mutant("gexfmutual", GX, 'throw ParseError(word.elementsEqual("mutual".utf8) ? .unsupported : .invalidValue, at: attribute.nameStart)',
           "throw ParseError(.invalidValue, at: attribute.nameStart)", mode="stmt"),
    Mutant("gexfdynamic", GX, 'throw ParseError(word.elementsEqual("dynamic".utf8) ? .unsupported : .invalidValue, at: a.nameStart)',
           "throw ParseError(.invalidValue, at: a.nameStart)", mode="stmt"),
    Mutant("gexfname", GX, 'if !scratch.isEmpty { graphAttribute("name", .string(String(decoding: scratch, as: UTF8.self))) }',
           'graphAttribute("name", .string(String(decoding: scratch, as: UTF8.self)))', mode="stmt"),
    Mutant("gexfclass", GX, "domain = 1", "domain = 0", mode="stmt"),
    Mutant("gexfdupattribute", GX, "if attributeNumbers[domain][scratch] != nil { throw ParseError(.duplicateKey, at: idAttribute.nameStart) }", "", mode="stmt"),
    Mutant("gexftitle", GX, "title = String(decoding: id, as: UTF8.self)", 'title = ""', mode="stmt"),
    Mutant("gexftypeinteger", GX, "type = .integer", "type = .string", mode="stmt"),
    Mutant("gexftypedouble", GX, "type = .double", "type = .integer", mode="stmt"),
    Mutant("gexftypeunknown", GX, "throw ParseError(.invalidValue, at: t.nameStart)", "type = .string", mode="stmt"),
    Mutant("gexfdefaultelements", GX, "if defaultHasElements { throw ParseError(.invalidValue, at: defaultOffset) }", "", mode="stmt"),
    Mutant("gexfdefaultonce", GX, "if attributes[d][k].defaultValue == nil { defaults[d].append(k) }", "defaults[d].append(k)", mode="stmt"),
    Mutant("gexfdupnode", GX, "guard inserted else { throw ParseError(.duplicateVertex, at: idAttribute.nameStart) }", "", mode="stmt"),
    Mutant("gexfnodelabel", GX, "record(element, labelNumber(), .string(String(decoding: scratch, as: UTF8.self)))", "", mode="stmt", nth=0),
    Mutant("gexfedgelabel", GX, "record(element, labelNumber(), .string(String(decoding: scratch, as: UTF8.self)))", "", mode="stmt", nth=1),
    Mutant("gexfnested", GX, "stack.append(.nodes)", "stack.append(.skip)", mode="stmt", nth=1),
    Mutant("gexfstamp", GX, "stamps[element.domain][k] = element.generation", "", mode="stmt"),
    Mutant("gexfundeclaredkey", GX, "ParseError(.undeclaredKey, at: f.nameStart)", "ParseError(.undeclaredKey, at: tag.offset)"),
    Mutant("gexfundeclaredvertex", GX, "ParseError(.undeclaredVertex, at: attribute.nameStart)", "ParseError(.invalidVertex, at: attribute.nameStart)"),
    Mutant("gexfedgetype", GX, 'if let a = scanner.attribute("type"), try edgeType(a, scanner) != Direction.isDirected {\n                throw ParseError(.unsupported, at: a.nameStart)\n            }', "", mode="stmt"),
    Mutant("gexfweight", GX, "record(element, weightNumber(), value)", "", mode="stmt"),
    Mutant("gexfweightat", GX, "try _graphMLValue(.double, bytes, at: w.nameStart)", "try _graphMLValue(.double, bytes, at: tag.offset)"),
    Mutant("gexfscratch", GX, "scratch.removeAll(keepingCapacity: true)", "", mode="stmt"),
    Mutant("gexfbudget", GX, "try budget.spend(1, at: element.offset)", "", mode="stmt"),
    Mutant("gexfdefaultgiven", GX, "stamps[d][k] != element.generation", "true"),
    Mutant("gexfnograph", GX, "guard reader.graphOffset != nil else { throw ParseError(.syntax, at: reader.rootOffset) }", "", mode="stmt"),
    Mutant("gexfnames", GX, "buffer.names = reader.names", "", mode="stmt"),
    Mutant("gexfwlabel", GX, "guard case .string(let s) = pair.value, _isXMLRepresentable(s) else { throw .invalidValue }", "_ = pair", mode="stmt", nth=0),
    Mutant("gexfwweight", GX, "switch pair.value {\n                case .integer, .double: break\n                default: throw .invalidValue\n                }", "", mode="stmt"),
    Mutant("gexfwids", GX, "numbering[d][local] = k", "numbering[d][local] = 0", mode="stmt"),
    Mutant("gexfwedgeid", GX, "number += 1", "", mode="stmt"),
    Mutant("gexfwclass", GX, '["node", "edge"]', '["node", "node"]'),
    Mutant("gexfwnodelabel", GX, 'out.appendASCII("\\" label=\\"")', 'out.appendASCII("\\" title=\\"")', mode="stmt", nth=0),
    Mutant("gexfwweightattr", GX, 'out.appendASCII("\\" weight=\\"")', 'out.appendASCII("\\" w=\\"")', mode="stmt"),
    Mutant("gexfwvalues", GX, 'pair.key != "label" && pair.key != "weight"', 'pair.key != "label"'),
    Mutant("gexfwnan", GX, 'out.appendASCII("NaN")', 'out.appendASCII("nan")', mode="stmt"),
    Mutant("gexfwinf", GX, 'out.appendASCII(x < 0 ? "-INF" : "INF")', 'out.appendASCII("INF")', mode="stmt"),
    Mutant("gexfwdirected", GX, 'Source.isDirected ? "  <graph defaultedgetype=\\"directed\\" mode=\\"static\\">\\n" : "  <graph defaultedgetype=\\"undirected\\" mode=\\"static\\">\\n"',
           '"  <graph defaultedgetype=\\"directed\\" mode=\\"static\\">\\n"'),

    # LEDA: the header, the counted lines, the information, and the writer.
    Mutant("ledaheader", LD, 'guard fields.count == 1, _matches(text, fields[0].0, fields[0].1, "LEDA.GRAPH") else { throw ParseError(.syntax, at: line.start) }', "", mode="stmt"),
    Mutant("ledacomment", LD, 'if q < line.end && text[q] != UInt8(ascii: "#") { return line }', "if q < line.end { return line }", mode="stmt"),
    Mutant("ledatypeint", LD, 'self = .integer', 'self = .string', mode="stmt"),
    Mutant("ledatypedouble", LD, 'self = .double', 'self = .integer', mode="stmt"),
    Mutant("ledakind", LD, "if directed != Direction.isDirected { throw ParseError(.kindMismatch, at: fields[0].0) }", "", mode="stmt"),
    Mutant("ledadirection", LD, 'throw ParseError(.invalidValue, at: fields[0].0)', 'directed = true', mode="stmt"),
    Mutant("ledabound", LD, "if n > _vertexBound(maximumVertexCount, inputCount: text.count) { throw ParseError(.limitExceeded, at: fields[0].0) }", "", mode="stmt"),
    Mutant("ledabrackets", LD, 'text[e &- 2] == UInt8(ascii: "}")', 'true'),
    Mutant("ledatrim", LD, "while e > s && _isBlank(text[e &- 1]) { e &-= 1 }", "", mode="stmt"),
    Mutant("ledavoid", LD, "self = .void", "self = .string", mode="stmt"),
    Mutant("ledanodelabel", LD, "if let value = try _ledaInformation(text, line.start, line.end, type: types[0]) { buffer.recordVertex(keys[i], 0, value) }", "_ = try _ledaInformation(text, line.start, line.end, type: types[0])", mode="stmt"),
    Mutant("ledaedgefields", LD, "if fields.count < 4 { throw ParseError(.syntax, at: line.end) }", "", mode="stmt"),
    Mutant("ledafast", LD, "a >= 1 && a <= n && b >= 1 && b <= n", "a >= 1 && b >= 1"),
    Mutant("ledareversal", LD, "if reversal > m { throw ParseError(.indexOutOfRange, at: fields[2].0) }", "", mode="stmt"),
    Mutant("ledaedgelabel", LD, "if let value = try _ledaInformation(text, fields[3].0, line.end, type: types[1]) { buffer.record(edge, 0, value) }", "_ = try _ledaInformation(text, fields[3].0, line.end, type: types[1])", mode="stmt"),
    Mutant("ledaextra", LD, "if let extra = _nextLEDALine(text, &start) { throw ParseError(.syntax, at: extra.start) }", "", mode="stmt"),
    Mutant("ledawnils", LD, "if nils && type != .void && type != .string { throw .typeMismatch }", "", mode="stmt"),
    Mutant("ledawmixed", LD, "guard (type == .integer || type == .double) && (next == .integer || next == .double) else { throw .typeMismatch }", "", mode="stmt"),
    Mutant("ledawpromote", LD, "if type == .double { _appendPythonDouble(Double(i), to: &out) } else { out.appendDecimal(i) }", "out.appendDecimal(i)", mode="stmt"),
    Mutant("ledawlinefeed", LD, "for b in s.utf8 where b == 0x0A || b == 0x0D { throw .invalidValue }", "", mode="stmt"),
    Mutant("ledawdirected", LD, 'Source.isDirected ? "-1\\n" : "-2\\n"', '"-1\\n"'),
    Mutant("ledawone", LD, "out.appendDecimal(v &+ 1)", "out.appendDecimal(v)", mode="stmt"),
]
