"""Writes the catalog-row test files of Tests/GraphFormatsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with pydot==4.0.1 \
        python3 Tests/Catalogs/GraphFormats/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/GraphFormatsTests

First checks that ref.py's model reproduces cases.md byte for byte, then re-runs every row on the
model, checks that the model's result renders to the row's Expected cell, and writes one @Test per
row, one file per format:

  * a read row calls the reader on the row's target with closures that record every attribute
    (or Mermaid label) call, keys in first-set order and the last value set, then checks the
    vertices in order, every edge position with its endpoints (stored orientation, undirected),
    the counts, and the recorded attributes of every vertex, edge and the graph, nothing more;
  * an error row checks the ParseError's kind, line, column and byte offset (after a byte-order
    mark), the offset computed from the model's position;
  * a write row builds the row's graph (DirectedPseudograph / Pseudograph, vertices then edges in
    position order), passes its attributes through the writer's closures, and checks every byte.

The precondition file holds the hand-written exit tests of extra_traps.swift (the catalog has no
trap rows: the writers' preconditions are api.md's, not catalog values). They cover the closures'
contract only; data a format cannot hold throws WriteError (GraphFormatsWriteErrorTests.swift).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "GraphFormatsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as fh:
    assert fh.read() == TEXT, "ref.py does not reproduce cases.md (run ref.py --write after review)"
ROWS = {}
for line in TEXT.split("\n"):
    if line.startswith("| GF-"):
        ROWS[line.split(" | ")[0][2:]] = line
CASES = ref.CASES
assert len(CASES) == len(ROWS) == 592
for c in CASES:
    r = ref.evaluate(c)
    cells = ROWS[c["id"]].split(" | ")
    if c["kind"] == "read":
        shown = ref.md(ref.fmt_graph(r)) if isinstance(r, ref.ParseError) else ref.code(ref.fmt_graph(r))
        assert cells[4] == ref.code(ref.literal(c["text"])), c["id"]
    else:
        shown = ref.code(ref.literal(r))
        assert cells[4] == ref.code(ref.fmt_graph(c["graph"])), c["id"]
    assert cells[5].rstrip(" |") == shown, c["id"]

# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------


def lit(s):
    """A one-line Swift string literal; controls, the BOM, DEL and non-ASCII whitespace as \\u{…}."""
    out = ['"']
    for ch in s:
        o = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif o < 0x20 or o == 0x7F or o == 0xFEFF or (o > 0x7F and ch.isspace()):
            out.append("\\u{%X}" % o)
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def value(x):
    if type(x) is bool:
        return ".boolean(%s)" % ("true" if x else "false")
    if type(x) is int:
        return ".integer(%d)" % x
    if type(x) is float:
        if math.isnan(x):
            return ".double(.nan)"
        if math.isinf(x):
            return ".double(%s.infinity)" % ("-" if x < 0 else "")
        return ".double(%s)" % repr(x)
    return ".string(%s)" % lit(x)


def vname(v):
    return str(v) if isinstance(v, int) else lit(v)


def is_nan(x):
    return type(x) is float and math.isnan(x)


def arr(items):
    return "[" + ", ".join(items) + "]"


def kv(pairs):
    return "[" + ", ".join(f"{k}: {v}" for k, v in pairs) + "]" if pairs else "[:]"


def attribute_pairs(pairs):
    """The pairs a writer's attribute closure returns, in writing order."""
    return "[" + ", ".join(f"({k}, {v})" for k, v in pairs) + "]"


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------
TYPE = {k: v[0] for k, v in ref.TARGETS.items()}
FORMAT_LABEL = ref.LABEL


def title(c):
    return '    @Test("%s %s")' % (c["id"], c["case"].replace("\\", "\\\\").replace('"', '\\"'))


def fname(c):
    return "gf" + c["id"][3:]


def input_lines(c):
    t = c["text"]
    if isinstance(t, bytes):
        try:
            t.decode("utf-8")
            assert False, "bytes rows are not UTF-8"
        except UnicodeDecodeError:
            pass
        return ["        let input: [UInt8] = [" + ", ".join("0x%02X" % b for b in t) + "]"], "input"
    return ["        let input = " + lit(t)], "input.utf8"


def byte_offset(c, r):
    raw = c["text"].encode() if isinstance(c["text"], str) else c["text"]
    if isinstance(r.offset, tuple):
        return r.offset[1]
    text, _ = ref.decode(raw)
    return len(text[:r.offset].encode())


def op_comment(c):
    return ref.op_of(c)


def attribute_checks(var_keys, var_values, rows, key_of):
    """rows: [(key, {name: value})], only non-empty ones."""
    lines = []
    lines.append(f"        #expect({var_keys} == {kv([(key_of(k), arr(lit(n) for n in a)) for k, a in rows])})")
    if not any(is_nan(x) for _, a in rows for x in a.values()):
        lines.append(f"        #expect({var_values} == {kv([(key_of(k), kv([(lit(n), value(x)) for n, x in a.items()])) for k, a in rows])})")
    else:
        lines.append(f"        #expect({var_values}.count == {len(rows)})")
        for k, a in rows:
            for n, x in a.items():
                sub = f"{var_values}[{key_of(k)}]?[{lit(n)}]"
                if is_nan(x):
                    lines.append(f"        #expect({{ if case .double(let x)? = {sub} {{ x.isNaN }} else {{ false }} }}())")
                else:
                    lines.append(f"        #expect({sub} == {value(x)})")
    return lines


def read_test(c):
    r = ref.evaluate(c)
    fmt, target = c["fmt"], c["target"]
    typ = TYPE[target]
    directed = ref.TARGETS[target][1]
    vint = ref.TARGETS[target][3] is int
    vt = "Int" if vint else "String"
    lines = [title(c), f"    func {fname(c)}() {{" if isinstance(r, ref.ParseError) else f"    func {fname(c)}() throws {{"]
    lines.append(f"        // {op_comment(c)} → {ref.fmt_graph(r)}")
    il, arg = input_lines(c)
    lines += il
    label = FORMAT_LABEL[fmt]
    columns = c["kw"].get("columns")
    col_arg = f", columns: {arr(lit(x) for x in columns)}" if columns is not None else ""
    if c["kw"].get("delimiter") is not None:
        col_arg += f", delimiter: {lit(c['kw']['delimiter'])}"
    if c["kw"].get("maximumVertexCount") is not None:
        col_arg += f", maximumVertexCount: {c['kw']['maximumVertexCount']}"
    if isinstance(r, ref.ParseError):
        lines.append("        do {")
        lines.append(f"            let graph = try {typ}({label}: {arg}{col_arg})")
        lines.append(f'            Issue.record("expected {r.kind}, read \\(graph)")')
        lines.append("        } catch {")
        lines.append(f"            #expect(error.kind == .{r.kind})")
        lines.append(f"            #expect([error.line, error.column, error.byteOffset] == [{r.line}, {r.column}, {byte_offset(c, r)}])")
        lines.append("        }")
        lines.append("    }")
        return lines
    has_va = fmt in ("dot", "graphML", "nodeLinkJSON", "gml", "pajek", "metis", "cytoscapeJSON")
    has_ea = fmt in ("dot", "graphML", "nodeLinkJSON", "matrixMarket", "edgeList", "gml", "pajek", "metis",
                     "cytoscapeJSON") or (fmt == "dimacs" and directed)
    has_ga = fmt in ("dot", "graphML", "nodeLinkJSON", "gml", "pajek", "cytoscapeJSON")
    closures = []
    if has_va:
        lines.append(f"        var vertexKeys: [{vt}: [String]] = [:]")
        lines.append(f"        var vertexValues: [{vt}: [String: AttributeValue]] = [:]")
        closures.append("vertexAttribute: { v, key, value in\n"
                        "            if vertexValues[v, default: [:]].updateValue(value, forKey: key) == nil { vertexKeys[v, default: []].append(key) }\n"
                        "        }")
    if has_ea:
        lines.append("        var edgeKeys: [Int: [String]] = [:]")
        lines.append("        var edgeValues: [Int: [String: AttributeValue]] = [:]")
        closures.append("edgeAttribute: { e, key, value in\n"
                        "            if edgeValues[e, default: [:]].updateValue(value, forKey: key) == nil { edgeKeys[e, default: []].append(key) }\n"
                        "        }")
    if has_ga:
        lines.append("        var graphKeys: [String] = []")
        lines.append("        var graphValues: [String: AttributeValue] = [:]")
        closures.append("graphAttribute: { key, value in\n"
                        "            if graphValues.updateValue(value, forKey: key) == nil { graphKeys.append(key) }\n"
                        "        }")
    if fmt == "mermaid":
        lines.append(f"        var vertexLabels: [{vt}: String] = [:]")
        lines.append("        var edgeLabels: [Int: String] = [:]")
        closures.append("vertexLabel: { v, label in vertexLabels[v] = label }")
        closures.append("edgeLabel: { e, label in edgeLabels[e] = label }")
    call = f"try {typ}({label}: {arg}{col_arg}" + "".join(", " + x for x in closures) + ")"
    lines.append(f"        let graph = {call}")
    names = [vname(v) for v in r.vertices]
    lines.append(f"        #expect(Array(graph.vertices) == {arr(names)})")
    lines.append(f"        #expect(graph.vertexCount == {len(r.vertices)} && graph.edgeCount == {len(r.edges)})")
    lines.append(f"        #expect(Array(graph.edges.indices) == {arr(str(p) for p in range(len(r.edges)))})")
    ends = arr(arr([vname(r.vertices[u]), vname(r.vertices[v])]) for u, v in r.edges)
    if directed:
        lines.append(f"        #expect(graph.edges.indices.map {{ [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] }} == {ends})")
    else:
        lines.append(f"        #expect(graph.edges.map {{ [$0.u, $0.v] }} == {ends})")
    vkey = (lambda k: str(k)) if vint else lit
    if has_va:
        lines += attribute_checks("vertexKeys", "vertexValues",
                                  [(v, a) for v, a in zip(r.vertices, r.vattrs) if a], vkey)
    if has_ea:
        lines += attribute_checks("edgeKeys", "edgeValues", [(p, a) for p, a in enumerate(r.eattrs) if a], str)
    if has_ga:
        lines.append(f"        #expect(graphKeys == {arr(lit(k) for k in r.gattrs)})")
        lines.append(f"        #expect(graphValues == {kv([(lit(k), value(x)) for k, x in r.gattrs.items()])})")
    if fmt == "mermaid":
        lines.append(f"        #expect(vertexLabels == {kv([(vkey(v), lit(a['label'])) for v, a in zip(r.vertices, r.vattrs) if a])})")
        lines.append(f"        #expect(edgeLabels == {kv([(str(p), lit(a['label'])) for p, a in enumerate(r.eattrs) if a])})")
        assert all(set(a) <= {"label"} for a in r.vattrs + r.eattrs)
    lines.append("    }")
    return lines


def switch_closure(param, cases, indent="        "):
    """A closure returning the attribute pairs by a switch over its argument."""
    if not cases:
        return None
    out = [f"{param} in", f"{indent}    switch {param} {{"]
    for k, pairs in cases:
        out.append(f"{indent}    case {k}: {attribute_pairs([(lit(n), value(x)) for n, x in pairs.items()])}")
    out.append(f"{indent}    default: []")
    out.append(f"{indent}    }}")
    return "{ " + ("\n".join(out)) + f"\n{indent}}}"


def label_closure(param, cases, indent="        "):
    if not cases:
        return None
    out = [f"{param} in", f"{indent}    switch {param} {{"]
    for k, s in cases:
        out.append(f"{indent}    case {k}: {lit(s)}")
    out.append(f"{indent}    default: nil")
    out.append(f"{indent}    }}")
    return "{ " + ("\n".join(out)) + f"\n{indent}}}"


def write_test(c):
    g, kw, fmt = c["graph"], c["kw"], c["fmt"]
    out = ref.write_output(c)
    lines = [title(c), f"    func {fname(c)}() {{"]
    lines.append(f"        // {op_comment(c)} on {ref.fmt_graph(g)}")
    vint = bool(g.vertices) and isinstance(g.vertices[0], int)
    vt = "Int" if vint else "String"
    if g.directed:
        typ = f"DirectedPseudograph<{vt}>"
        edges = arr(f"DirectedEdge(from: {vname(g.vertices[u])}, to: {vname(g.vertices[v])})" for u, v in g.edges)
    else:
        typ = f"Pseudograph<{vt}>"
        edges = arr(f"UndirectedEdge({vname(g.vertices[u])}, {vname(g.vertices[v])})" for u, v in g.edges)
    if g.edges:
        lines.append(f"        let graph = {typ}(vertices: {arr(vname(v) for v in g.vertices)}, edges: {edges})")
    elif g.vertices:
        lines.append(f"        let graph = {typ}(vertices: {arr(vname(v) for v in g.vertices)})")
    else:
        lines.append(f"        let graph = {typ}()")
    vcases = [(vname(v), a) for v, a in zip(g.vertices, g.vattrs) if a]
    ecases = [(str(p), a) for p, a in enumerate(g.eattrs) if a]
    args = []
    if fmt in ("dot", "graphML", "nodeLinkJSON", "gml", "cytoscapeJSON", "pajek"):
        vc = switch_closure("v", vcases)
        ec = switch_closure("e", ecases)
        if vc:
            args.append("vertexAttributes: " + vc)
        if ec:
            args.append("edgeAttributes: " + ec)
        if g.gattrs:
            assert fmt != "pajek"
            args.append("graphAttributes: " + attribute_pairs([(lit(k), value(x)) for k, x in g.gattrs.items()]))
        call = {"dot": "writeDOT", "graphML": "writeGraphML", "nodeLinkJSON": "writeNodeLinkJSON", "gml": "writeGML",
                "cytoscapeJSON": "writeCytoscapeJSON", "pajek": "writePajek"}[fmt]
    elif fmt in ("graph6", "sparse6", "digraph6"):
        call = {"graph6": "writeGraph6", "sparse6": "writeSparse6", "digraph6": "writeDigraph6"}[fmt]
        if kw.get("header"):
            args.append("header: true")
    elif fmt in ("dimacs", "metis"):
        call = {"dimacs": "writeDIMACS", "metis": "writeMETIS"}[fmt]
        if kw.get("weight") is not None:
            lines.append(f"        let weights: [Int] = {arr(str(x) for x in kw['weight'])}")
            args.append("weight: { weights[$0] }")
    elif fmt == "matrixMarket":
        call = "writeMatrixMarket"
        if "weight" in kw:
            w = kw["weight"]
            if all(type(x) is int for x in w):
                lines.append(f"        let weights: [Int] = {arr(str(x) for x in w)}")
            else:
                lines.append(f"        let weights: [Double] = {arr(value(float(x))[len('.double('):-1] for x in w)}")
            args.append("weight: { weights[$0] }")
    elif fmt == "edgeList":
        call = "writeEdgeList"
        if "columns" in kw:
            args.append("columns: " + arr(lit(x) for x in kw["columns"]))
        if kw.get("delimiter") is not None:
            args.append("delimiter: " + lit(kw["delimiter"]))
        ec = switch_closure("e", ecases)
        if ec and "columns" in kw:
            args.append("edgeAttributes: " + ec)
    elif fmt == "adjacencyList":
        call = "writeAdjacencyList"
    else:
        call = "writeMermaid"
        vl = label_closure("v", [(vname(v), a["label"]) for v, a in zip(g.vertices, g.vattrs) if "label" in a])
        el = label_closure("e", [(str(p), a["label"]) for p, a in enumerate(g.eattrs) if "label" in a])
        if vl:
            args.append("vertexLabel: " + vl)
        if el:
            args.append("edgeLabel: " + el)
    lines.append('        var output = ""')
    # Every writer but Matrix Market's throws WriteError on data its format cannot hold.
    throwing = call not in ("writeMatrixMarket", "writeSparse6", "writeDIMACS")
    if throwing:
        lines[1] = f"    func {fname(c)}() throws {{"
    lines.append("        " + ("try " if throwing else "") + f"graph.{call}(to: &output" + "".join(", " + a for a in args) + ")")
    lines.append(f"        #expect(output == {lit(out)})")
    lines.append("    }")
    return lines


def id_ranges(fmts, kind):
    """The catalog IDs of a file's rows of one kind, as runs: GF-001 – GF-042, GF-226."""
    nums = [int(c["id"][3:]) for c in CASES if c["fmt"] in fmts and c["kind"] == kind]
    runs, start = [], None
    for k, n in enumerate(nums):
        if start is None:
            start = n
        if k + 1 == len(nums) or nums[k + 1] != n + 1:
            runs.append(f"GF-{start:03d}" + (f" – GF-{n:03d}" if n != start else ""))
            start = None
    return ", ".join(runs)


def catalog_comment(title, fmts, text):
    reads, writes = id_ranges(fmts, "read"), id_ranges(fmts, "write")
    head = f"{title} (catalog {reads} read" + (f", {writes} write" if writes else "") + "): "
    words, lines, line = (head + text).split(" "), [], ""
    for w in words:
        if len(line) + len(w) + 1 > 100 and line:
            lines.append(line)
            line = w
        else:
            line = w if not line else line + " " + w
    lines.append(line)
    return "\n// ".join(lines)


FILES = [
    ("GraphFormatsDOTTests.swift", "GraphFormats DOT", ("dot",), "DOT",
     "the grammar with subgraphs and ports, values read as strings, node and edge defaults applied to later "
     "statements and scoped by subgraphs, strict merging, DOT's quoting; the writer's canonical form, quoting only "
     "where an ID needs it."),
    ("GraphFormatsGraphMLTests.swift", "GraphFormats GraphML", ("graphML",), "GraphML",
     "the XML subset (no DTD, no entities but the five), typed keys with defaults, nested graphs read into the one "
     "graph, edges resolved after the nodes, unsupported features rejected precisely; the writer's keys by first "
     "appearance, graph keys first."),
    ("GraphFormatsNodeLinkJSONTests.swift", "GraphFormats node-link JSON", ("nodeLinkJSON",), "Node-link JSON",
     "the layout over strict RFC 8259 JSON, scalar attributes only, array ids as their canonical text; ref.py "
     "checks the write rows byte for byte against json.dumps(node_link_data)."),
    ("GraphFormatsMatrixMarketTests.swift", "GraphFormats Matrix Market", ("matrixMarket",), "Matrix Market",
     "coordinate matrices into vertices 0..<n, symmetric files into either kind, weights under \"weight\"; ref.py "
     "checks the write rows byte for byte against SciPy's mmwrite."),
    ("GraphFormatsEdgeListTests.swift", "GraphFormats edge list", ("edgeList",), "Edge list",
     "two fields and the declared columns per line, typed by their text, or a NetworkX data dict; whitespace or a "
     "delimiter between fields; ref.py checks the write rows byte for byte against NetworkX's write_edgelist."),
    ("GraphFormatsAdjacencyListTests.swift", "GraphFormats adjacency list", ("adjacencyList",), "Adjacency list",
     "a head and its neighbours per line; ref.py checks the write rows byte for byte against NetworkX's "
     "write_adjlist without its header."),
    ("GraphFormatsMermaidTests.swift", "GraphFormats Mermaid", ("mermaid",), "Mermaid",
     "flowcharts with every supported shape and link, labels kept and styling skipped; the writer quotes every "
     "label."),
    ("GraphFormatsGMLTests.swift", "GraphFormats GML", ("gml",), "GML",
     "Himsolt's key-value lists, nodes named by their labels, typed values, lists skipped, edges resolved after "
     "the graph; ref.py checks the write rows byte for byte against NetworkX's write_gml."),
    ("GraphFormatsPajekTests.swift", "GraphFormats Pajek", ("pajek",), "Pajek",
     "*vertices with labels, coordinates and pairs, *arcs and *edges with weights, the list sections, shlex "
     "quoting; ref.py checks the write rows byte for byte against NetworkX's write_pajek."),
    ("GraphFormatsNautyTests.swift", "GraphFormats graph6, sparse6, digraph6", ("graph6", "sparse6", "digraph6"),
     "graph6, sparse6 and digraph6",
     "nauty's formats on vertices 0..<n, with and without headers; ref.py checks the graph6 and sparse6 write "
     "rows byte for byte against NetworkX, except where nauty's padding rule differs."),
    ("GraphFormatsDIMACSTests.swift", "GraphFormats DIMACS", ("dimacs",), "DIMACS",
     "shortest-path files (p sp, weighted arcs) and clique and colouring files (p edge, p col) on vertices "
     "0..<n, the declared edge count checked."),
    ("GraphFormatsMETISTests.swift", "GraphFormats METIS", ("metis",), "METIS",
     "the header with its fmt and ncon, one line per vertex, every edge listed from both ends, sizes and "
     "weights."),
    ("GraphFormatsCytoscapeJSONTests.swift", "GraphFormats Cytoscape JSON", ("cytoscapeJSON",), "Cytoscape JSON",
     "elements as an object or an array, data as an object or NetworkX's pairs, ids as text; ref.py checks the "
     "write rows byte for byte against json.dumps(cytoscape_data)."),
]
IMPORTS = {"AdjacencyListModule": ("AdjacencyList<", "UndirectedAdjacencyList<"),
           "Multigraphs": ("DirectedPseudograph<", "Pseudograph<")}


def write(name, suite, fmts, heading, text):
    comment = catalog_comment(heading, fmts, text)
    tests = [read_test(c) if c["kind"] == "read" else write_test(c) for c in CASES if c["fmt"] in fmts]
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphFormats", "GraphProtocols", "Testing"]
    for module, needles in IMPORTS.items():
        if any(n in text for n in needles):
            imports.append(module)
    imports.sort(key=str.lower)
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", f'@Suite("{suite}")', f"struct {name[:-6]} {{"]
    out += body
    out.append("}")
    with open(os.path.join(OUT, name), "w") as f:
        f.write("\n".join(out) + "\n")
    return len(tests)


def write_traps():
    extra = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n")
    out = ["// Writer preconditions (api.md; the catalog has no trap rows): each trapping call runs in a child",
           "// process (exit test), and the same call without the fault then runs in this process, so the",
           "// trap is the fault's. Data a format cannot hold throws instead (GraphFormatsWriteErrorTests).",
           "// Hand-written in extra_traps.swift; swiftgen.py splices them in here.",
           "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    imports = ["GraphFormats", "GraphProtocols", "GrafluentTestSupport", "Testing"]
    for module, needles in IMPORTS.items():
        if any(n in extra for n in needles):
            imports.append(module)
    imports.sort(key=str.lower)
    out += ["import " + m for m in imports]
    out += ["", '@Suite("GraphFormats writer preconditions", .tags(.precondition))',
            "struct GraphFormatsPreconditionTests {", extra, "}"]
    with open(os.path.join(OUT, "GraphFormatsPreconditionTests.swift"), "w") as f:
        f.write("\n".join(out) + "\n")
    return extra.count("@Test(")


os.makedirs(OUT, exist_ok=True)
total = 0
for name, suite, fmts, heading, text in FILES:
    k = write(name, suite, fmts, heading, text)
    print(name, k)
    total += k
assert total == len(CASES), total
print("GraphFormatsPreconditionTests.swift", write_traps())
reads = sum(c["kind"] == "read" for c in CASES)
errors = sum(c["kind"] == "read" and isinstance(ref.evaluate(c), ref.ParseError) for c in CASES)
print(f"catalog rows {total}: {reads - errors} reads, {errors} errors, {total - reads} writes")
