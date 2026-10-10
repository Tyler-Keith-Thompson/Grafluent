"""Writes the catalog-row test files of Tests/MultigraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 python3 swiftgen.py [OUT_DIR]   # default: Tests/MultigraphsTests

First checks that ref.py's model reproduces cases.md exactly, then re-evaluates every row with the
model (structured values, not the printed cells), asserts each value matches its catalog cell, and
writes one @Test per row. Final states are written out in full: `vertices`, `edges` in stored
orientation, every vertex's rows (both rows for directed types, empty ones included), and, beyond
the catalog cell, `edges(between:and:)` / `edges(from:to:)` and `edgeCount` for every pair that has
an edge, from the model (whose class order ref.py checks against NetworkX's key order).
"""
import os, sys, json

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "MultigraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every `case` row
# ---------------------------------------------------------------------------------------------
STRUCT = []
_orig_case = ref.case


def _case(group, title, kind, V, E, ops=(), note=None):
    STRUCT.append((len(ref.CASES) + 1, group, title, kind, V, E, list(ops)))
    _orig_case(group, title, kind, V, E, ops, note)


ref.case = _case
ref.define()
text = ref.render()
with open(ref.CASES_MD) as f:
    assert f.read() == text, "cases.md is not ref.py's output"
CELLS = {}
for line in text.splitlines():
    if line.startswith("| MG-"):
        parts = [p.strip() for p in line.strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
assert len(CELLS) == 192
CASE_ROWS = {n: (g, t, k, V, E, ops) for n, g, t, k, V, E, ops in STRUCT}


def cell(n):
    return CELLS[n][4]


def title(n):
    return CELLS[n][2]


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def lit(x):
    return json.dumps(x, ensure_ascii=False) if isinstance(x, str) else str(x)


def is_directed(kind):
    return kind.startswith("Directed") or kind == "AdjacencyList"


def vty(*seqs):
    for s in seqs:
        for x in s:
            if isinstance(x, (tuple, list)):
                if any(isinstance(y, str) for y in x):
                    return "String"
            elif isinstance(x, str):
                return "String"
    return "Int"


def arr(xs, t):
    return "[" + ", ".join(lit(x) for x in xs) + "]" + ("" if xs else " as [%s]" % t)


def nested(xss, t):
    return "[" + ", ".join("[" + ", ".join(lit(x) for x in xs) + "]" for xs in xss) + "]" + ("" if xss else " as [[%s]]" % t)


def edge_lit(kind, a, b):
    return ("DirectedEdge(from: %s, to: %s)" if is_directed(kind) else "UndirectedEdge(%s, %s)") % (lit(a), lit(b))


def edges_lit(kind, E, t):
    if not E:
        return "[] as [%s<%s>]" % ("DirectedEdge" if is_directed(kind) else "UndirectedEdge", t)
    return "[" + ", ".join(edge_lit(kind, a, b) for a, b in E) + "]"


def pair_label(kind):
    return ("from", "to") if is_directed(kind) else ("between", "and")


def ends(kind):
    return "[$0.source, $0.target]" if is_directed(kind) else "[$0.u, $0.v]"


def mutating(op):
    return op[0] in ("insV", "ins", "rm", "rmAt", "rmAll", "rmV", "rmAllEdges", "rmAllV")


def construct(kind, V, E, t, var="graph", mutable=True):
    """The build line, or None plus a nil check for a multigraph with a loop."""
    kw = "var" if mutable else "let"
    vs = arr(V, t)
    es = edges_lit(kind, E, t)
    if kind in ("Multigraph", "DirectedMultigraph"):
        return "%s %s = try #require(%s<%s>(vertices: %s, edges: %s))" % (kw, var, kind, t, vs, es)
    return "%s %s = %s<%s>(vertices: %s, edges: %s)" % (kw, var, kind, t, vs, es)


def state_lines(g, var="graph", t="Int", pairs=True, indent="        "):
    """Every value of the model's state, as #expect lines."""
    kind = g.kind
    out = []
    out.append("#expect(Array(%s.vertices) == %s)" % (var, arr(g.V, t)))
    out.append("#expect(%s.edges.map { %s } == %s)" % (var, ends(kind), nested([list(e) for e in g.edges()], t)))
    out.append("#expect(%s.vertexCount == %d)" % (var, len(g.V)))
    out.append("#expect(%s.edgeCount == %d)" % (var, len(g.rec)))
    for i, v in enumerate(g.V):
        if g.directed:
            out.append("#expect(Array(%s.successors(of: %s)) == %s)" % (var, lit(v), arr([g.V[w] for w in g.out[i]], t)))
            out.append("#expect(Array(%s.outEdges(of: %s)) == %s)" % (var, lit(v), arr(g.oute[i], "Int")))
            out.append("#expect(Array(%s.predecessors(of: %s)) == %s)" % (var, lit(v), arr([g.V[w] for w in g.inn[i]], t)))
            out.append("#expect(Array(%s.inEdges(of: %s)) == %s)" % (var, lit(v), arr(g.ine[i], "Int")))
        else:
            out.append("#expect(Array(%s.neighbors(of: %s)) == %s)" % (var, lit(v), arr([g.V[w] for w in g.nb[i]], t)))
            out.append("#expect(Array(%s.incidentEdges(of: %s)) == %s)" % (var, lit(v), arr(g.inc[i], "Int")))
    if pairs:
        seen = []
        for a, b in g.edges():
            k = (a, b) if g.directed else frozenset((a, b))
            if k in [s[0] for s in seen]:
                continue
            seen.append((k, a, b))
        f, s = pair_label(kind)
        for _, a, b in seen:
            ps = g.edges_between(a, b)
            out.append("#expect(Array(%s.edges(%s: %s, %s: %s)) == %s)" % (var, f, lit(a), s, lit(b), arr(ps, "Int")))
            out.append("#expect(%s.edgeCount(%s: %s, %s: %s) == %d)" % (var, f, lit(a), s, lit(b), len(ps)))
    return [indent + l for l in out]


def call_lines(g, op, t, indent="        "):
    """Applies `op` to the model and returns the Swift lines checking its result."""
    kind = g.kind
    sh = SHADOW[id(g)]
    name = op[0]
    result = ref.apply(g, sh, op)
    f, s = pair_label(kind)
    if name == "insV":
        ok = result == "inserted true"
        return [indent + "do { let result = graph.insert(%s); #expect(%sresult.inserted); #expect(result.memberAfterInsert == %s) }" % (lit(op[1]), "" if ok else "!", lit(op[1]))]
    if name == "ins":
        return [indent + "#expect(graph.insert(edge: %s) == %s)" % (edge_lit(kind, op[1], op[2]), result)]
    if name in ("rm", "rmAt"):
        call = "graph.remove(edge: %s)" % edge_lit(kind, op[1], op[2]) if name == "rm" else "graph.remove(edgeAt: %d)" % op[1]
        if result == "nil":
            return [indent + "#expect(%s == nil)" % call]
        sep = "→" if g.directed else "–"
        a, b = result.split(sep)
        a, b = json.loads(a), json.loads(b)
        if name == "rm":
            return [indent + "#expect(%s.map { %s } == %s)" % (call, ends(kind), "[%s, %s]" % (lit(a), lit(b)))]
        return [indent + "do { let removed = %s; #expect(%s == [%s, %s]) }" % (call, "[removed.source, removed.target]" if g.directed else "[removed.u, removed.v]", lit(a), lit(b))]
    if name == "rmAll":
        return [indent + "#expect(graph.removeAllEdges(%s: %s, %s: %s) == %s)" % (f, lit(op[1]), s, lit(op[2]), result)]
    if name == "rmV":
        return [indent + "#expect(graph.remove(%s) == %s)" % (lit(op[1]), "nil" if result == "nil" else result)]
    if name == "rmAllEdges":
        return [indent + "graph.removeAllEdges()"]
    if name == "rmAllV":
        return [indent + "graph.removeAll()"]
    if name == "between":
        ps = json.loads(result)
        return [indent + "#expect(Array(graph.edges(%s: %s, %s: %s)) == %s)" % (f, lit(op[1]), s, lit(op[2]), arr(ps, "Int")),
                indent + "#expect(graph.edges(%s: %s, %s: %s).count == %d)" % (f, lit(op[1]), s, lit(op[2]), len(ps))]
    if name == "count":
        return [indent + "#expect(graph.edgeCount(%s: %s, %s: %s) == %s)" % (f, lit(op[1]), s, lit(op[2]), result)]
    if name == "contains":
        return [indent + "#expect(graph.contains(edge: %s) == %s)" % (edge_lit(kind, op[1], op[2]), result)]
    if name == "deg":
        if g.directed:
            o, i, d = [int(x) for x in result.replace("out ", "").replace("in ", "").replace("degree ", "").split()]
            return [indent + "#expect(graph.outDegree(of: %s) == %d)" % (lit(op[1]), o),
                    indent + "#expect(graph.inDegree(of: %s) == %d)" % (lit(op[1]), i),
                    indent + "#expect(graph.degree(of: %s) == %d)" % (lit(op[1]), d)]
        return [indent + "#expect(graph.degree(of: %s) == %s)" % (lit(op[1]), result)]
    raise ValueError(op)


SHADOW = {}


def model(kind, V, E, ops=()):
    g, sh = ref.build(kind, V, E)
    SHADOW[id(g)] = sh
    for op in ops:
        ref.apply(g, sh, op)
    return g


def swift_call(kind, op):
    """The Swift text of a call, for comments."""
    return op_text(kind, op)


def op_text(kind, op):
    g = ref.new(kind)
    return ref.show_op(g, op)


def test_header(n, extra_tags=None):
    tags = ""
    if extra_tags:
        tags = ", .tags(%s)" % ", ".join(extra_tags)
    return ['    @Test("MG-%03d %s"%s)' % (n, title(n), tags)]


# ---------------------------------------------------------------------------------------------
# `case` rows
# ---------------------------------------------------------------------------------------------

def is_trap(n):
    return cell(n).startswith("trap")


def case_test(n):
    group, ttl, kind, V, E, ops = CASE_ROWS[n]
    t = vty(V, E, [o[1:] for o in ops])
    exp = cell(n)
    lines = test_header(n)
    lines.append("    func mg%03d() throws {" % n)
    lines.append("        // %s" % CELLS[n][3])
    g, sh = ref.build(kind, V, E)
    if g is None:
        assert exp == "init nil (self-loop)"
        lines.append("        #expect(%s<%s>(vertices: %s, edges: %s) == nil)" % (kind, t, arr(V, t), edges_lit(kind, E, t)))
        if not V:
            lines.append("        #expect(%s<%s>(edges: %s) == nil)" % (kind, t, edges_lit(kind, E, t)))
        lines.append("    }")
        return lines
    SHADOW[id(g)] = sh
    mut = any(mutating(o) for o in ops)
    if n == 14:
        # The builder: the listed vertex, then the edges.
        body = "; ".join([lit(v) for v in V] + [edge_lit(kind, a, b) for a, b in E])
        lines.append("        let graph = Pseudograph<%s> { %s }" % (t, body))
        lines.append("        #expect(graph == Pseudograph<%s>(vertices: %s, edges: %s))" % (t, arr(V, t), edges_lit(kind, E, t)))
    else:
        lines.append("        " + construct(kind, V, E, t, mutable=mut))
    for op in ops:
        lines += call_lines(g, op, t)
    # The catalog cell, rebuilt from the model.
    cs = cell(n)
    if " ⇒ " in cs:
        cs = cs.split(" ⇒ ")[1]
    assert cs == g.state(), (n, cs, g.state())
    lines.append("        // Final state.")
    lines += state_lines(g, t=t)
    lines.append("    }")
    if "try" not in "\n".join(lines):
        lines[len(test_header(n))] = "    func mg%03d() {" % n
    return lines


def trap_case_test(n):
    """A trap row from a `case`: the setup in a child process, then the trapping call."""
    group, ttl, kind, V, E, ops = CASE_ROWS[n]
    t = vty(V, E, [o[1:] for o in ops])
    lines = test_header(n)
    lines.append("    func mg%03d() async {" % n)
    lines.append("        // %s → %s" % (CELLS[n][3], cell(n)))
    *setup, last = ops
    assert not setup
    # Built from vertices and insertions, so the child never unwraps a failable initializer.
    inserts = ["graph.insert(edge: %s)" % edge_lit(kind, a, b) for a, b in E]
    name = last[0]
    if name == "ins":
        calls = ["graph.insert(edge: %s)" % edge_lit(kind, last[1], last[2])]
    elif name == "rmAt":
        calls = ["graph.remove(edgeAt: %d)" % last[1]]
    elif name == "deg" and is_directed(kind):
        calls = ["_ = graph.outDegree(of: %s)" % lit(last[1]), "_ = graph.inDegree(of: %s)" % lit(last[1]), "_ = graph.degree(of: %s)" % lit(last[1])]
    elif name == "deg":
        calls = ["_ = graph.degree(of: %s)" % lit(last[1])]
    else:
        raise ValueError(last)
    for call in calls:
        child_mutates = bool(inserts) or not call.startswith("_ =")
        lines.append("        await #expect(processExitsWith: .failure) {")
        lines.append("            %s graph = %s<%s>(vertices: %s)" % ("var" if child_mutates else "let", kind, t, arr(V, t)))
        for b in inserts:
            lines.append("            " + b)
        lines.append("            " + call)
        lines.append("        }")
    # The same setup in this process, without the trapping call: the trap is the call's.
    g = model(kind, V, E)
    lines.append("        // Without the call: the state it would apply to.")
    lines.append("        %s graph = %s<%s>(vertices: %s)" % ("var" if inserts else "let", kind, t, arr(V, t)))
    for b in inserts:
        lines.append("        " + b)
    lines += state_lines(g, t=t)
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Equality rows (MG-115 – MG-128)
# ---------------------------------------------------------------------------------------------
P, M, DP, DM = ref.P, ref.M, ref.DP, ref.DM
EQS = [
    ("same edges, other order", P, ([], [(0, 1), (0, 1), (1, 2)]), ([], [(1, 2), (0, 1), (1, 0)]), ()),
    ("copy count differs", P, ([], [(0, 1), (0, 1)]), ([], [(0, 1)]), ()),
    ("orientation ignored", P, ([], [(0, 1)]), ([], [(1, 0)]), ()),
    ("isolated vertex differs", P, ([2], [(0, 1)]), ([], [(0, 1)]), ()),
    ("vertex order ignored", P, ([0, 1, 2], []), ([2, 1, 0], []), ()),
    ("loop count differs", P, ([], [(0, 0)]), ([], [(0, 0), (0, 0)]), ()),
    ("after removal equal to fresh", P, ([], [(0, 1), (1, 2), (0, 1)]), ([], [(1, 2), (0, 1)]), (("rmAt", 0),)),
    ("directed orientation matters", DP, ([], [(0, 1)]), ([], [(1, 0)]), ()),
    ("directed copies", DP, ([], [(0, 1), (0, 1), (1, 0)]), ([], [(1, 0), (0, 1), (0, 1)]), ()),
    ("directed copy count differs", DP, ([], [(0, 1), (1, 0)]), ([], [(0, 1), (0, 1)]), ()),
    ("empty graphs", P, ([], []), ([], []), ()),
    ("multigraph same edges", M, ([], [(0, 1), (1, 0)]), ([], [(0, 1), (0, 1)]), ()),
    ("same edge multiset, different pairs", P, ([], [(0, 1), (2, 3)]), ([], [(0, 2), (1, 3)]), ()),
    ("strings", P, ([], [("a", "b"), ("b", "a")]), ([], [("b", "a"), ("a", "b")]), ()),
]


def equality_test(n, row):
    ttl, kind, (V1, E1), (V2, E2), ops = row
    assert title(n) == ttl
    g = model(kind, V1, E1, ops)
    h = model(kind, V2, E2)
    e = ref.equal(g, h)
    assert cell(n) == "== %s%s" % (str(e).lower(), "; equal hashes" if e else "")
    t = vty(V1, E1, V2, E2)
    throws = kind in (M, DM)
    lines = test_header(n, [".conformance"])
    lines.append("    func mg%03d()%s {" % (n, " throws" if throws else ""))
    lines.append("        // %s → %s" % (CELLS[n][3], cell(n)))
    lines.append("        " + construct(kind, V1, E1, t, var="lhs", mutable=bool(ops)))
    for op in ops:
        assert op[0] == "rmAt"
        lines.append("        lhs.remove(edgeAt: %d)" % op[1])
    lines.append("        " + construct(kind, V2, E2, t, var="rhs", mutable=False))
    if e:
        lines.append("        #expect(lhs == rhs)")
        lines.append("        #expect(rhs == lhs)")
        lines.append("        #expect(lhs.hashValue == rhs.hashValue)")
        lines.append("        #expect(Set([lhs, rhs]).count == 1)")
    else:
        lines.append("        #expect(lhs != rhs)")
        lines.append("        #expect(rhs != lhs)")
        lines.append("        #expect(Set([lhs, rhs]).count == 2)")
    lines.append("        #expect(lhs == lhs)")
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Codable rows (MG-129 – MG-153)
# ---------------------------------------------------------------------------------------------
TRIPS = [
    (P, [], [(0, 1), (0, 1), (1, 1)], ()),
    (P, [3], [(0, 1)], ()),
    (P, [], [(0, 1), (1, 2), (0, 1), (2, 2)], (("rmAt", 0),)),
    (P, ["a", "b"], [("b", "a"), ("a", "b")], ()),
    (M, [], [(0, 1), (1, 0)], ()),
    (DP, [], [(0, 1), (0, 1), (1, 0), (1, 1)], ()),
    (DM, [], [(0, 1), (0, 1)], ()),
    (P, [], [], ()),
]
CORRUPT = [
    (P, '{"vertices":[0,1],"edges":[0,1,0,1]}', "copies accepted"),
    (P, '{"vertices":[0],"edges":[0,0,0,0]}', "loops accepted"),
    (M, '{"vertices":[0],"edges":[0,0]}', "loop rejected"),
    (DM, '{"vertices":[0,1],"edges":[0,1,1,1]}', "directed loop rejected"),
    (DP, '{"vertices":[0],"edges":[0,0]}', "directed loop accepted"),
    (P, '{"vertices":[0,1],"edges":[0]}', "odd length"),
    (P, '{"vertices":[0,0],"edges":[]}', "repeated vertex"),
    (P, '{"vertices":[0,1],"edges":[0,2]}', "endpoint out of range"),
    (P, '{"vertices":[0,1],"edges":[-1,0]}', "negative endpoint"),
    (DP, '{"vertices":[],"edges":[0,0]}', "endpoint with no vertices"),
    (P, '{"edges":[]}', "missing vertices"),
    (DP, '{"vertices":[]}', "missing edges"),
    (P, '{"vertices":["a","b"],"edges":[1,0,0,1]}', "string vertices"),
    (DM, '{"vertices":[0,1],"edges":[0,1,0,1,1,0]}', "directed copies accepted"),
    (P, '{"vertices":[0,1],"edges":[0,1,1,1]}', "UndirectedAdjacencyList payload decodes as Pseudograph"),
    ("UndirectedAdjacencyList", '{"vertices":[0,1],"edges":[0,1,1,0]}', "Pseudograph payload with copies fails as UndirectedAdjacencyList"),
    (DM, '{"vertices":[0],"edges":[0,0]}', "AdjacencyList payload with a loop fails as DirectedMultigraph"),
]


def swift_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def sorted_payload(payload):
    d = json.loads(payload)
    return json.dumps({"edges": d["edges"], "vertices": d["vertices"]}, separators=(",", ":"), ensure_ascii=False)


def trip_test(n, row):
    kind, V, E, ops = row
    g = model(kind, V, E, ops)
    payload = ref.encode(g)
    back = ref.decode(kind, payload)
    assert cell(n) == "encodes %s; decodes to %s" % (payload, back.state()), n
    t = vty(V, E)
    throws = True
    lines = test_header(n, [".conformance"])
    lines.append("    func mg%03d()%s {" % (n, " throws" if throws else ""))
    lines.append("        // %s" % CELLS[n][3])
    lines.append("        " + construct(kind, V, E, t, mutable=bool(ops)))
    for op in ops:
        lines.append("        graph.remove(edgeAt: %d)" % op[1])
    lines.append("        let encoder = JSONEncoder()")
    lines.append("        encoder.outputFormatting = .sortedKeys")
    lines.append("        let data = try encoder.encode(graph)")
    lines.append("        #expect(String(decoding: data, as: UTF8.self) == %s)" % swift_string(sorted_payload(payload)))
    lines.append("        // The payload as the catalog writes it (vertices first) decodes the same way.")
    lines.append("        for payload in [data, Data(%s.utf8)] {" % swift_string(payload))
    lines.append("            let decoded = try JSONDecoder().decode(%s<%s>.self, from: payload)" % (kind, t))
    lines.append("            #expect(decoded == graph)")
    lines += state_lines(back, var="decoded", t=t, indent="            ")
    lines.append("        }")
    lines.append("    }")
    return lines


def corrupt_test(n, row):
    kind, payload, ttl = row
    assert title(n) == ttl
    r = ref.decode(kind, payload)
    exp = r if isinstance(r, str) else r.state()
    assert cell(n) == exp, (n, cell(n), exp)
    d = json.loads(payload)
    t = vty(d.get("vertices", []))
    lines = test_header(n, [".conformance"])
    lines.append("    func mg%03d() throws {" % n)
    lines.append("        // %s → %s" % (CELLS[n][3], cell(n)))
    lines.append("        let payload = Data(%s.utf8)" % swift_string(payload))
    if isinstance(r, str):
        lines.append("        do {")
        lines.append("            let decoded = try JSONDecoder().decode(%s<%s>.self, from: payload)" % (kind, t))
        lines.append('            Issue.record("decoded \\(decoded)")')
        if r.startswith("dataCorrupted("):
            msg = r[len("dataCorrupted("):-1]
            lines.append("        } catch let DecodingError.dataCorrupted(context) {")
            lines.append("            #expect(context.debugDescription == %s)" % swift_string(msg))
        else:
            key = r[len("keyNotFound("):-1]
            lines.append("        } catch let DecodingError.keyNotFound(key, _) {")
            lines.append("            #expect(key.stringValue == %s)" % swift_string(key))
        lines.append("        } catch {")
        lines.append('            Issue.record("unexpected error \\(error)")')
        lines.append("        }")
    else:
        lines.append("        let graph = try JSONDecoder().decode(%s<%s>.self, from: payload)" % (kind, t))
        lines += state_lines(r, t=t)
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Description rows (MG-154 – MG-159)
# ---------------------------------------------------------------------------------------------
DESCS = [(P, [], [(0, 1), (0, 1), (1, 1)]), (DP, [], [(0, 1), (0, 1), (1, 1)]), (P, [], []), (M, ["a"], [("a", "b"), ("b", "a")]),
         (DM, [], [(0, 1), (1, 0)]), (P, [], [(0, 1)] * 17)]


def description_test(n, row):
    kind, V, E = row
    g = model(kind, V, E)
    d, vs, es = ref.description(g)
    debug = "%s<%s>(vertexCount: %d, edgeCount: %d, vertices: %s, edges: %s)" % (kind, "String" if any(isinstance(v, str) for v in g.V) else "Int", len(g.V), len(g.rec), vs, es)
    assert cell(n) == "%s ‖ %s" % (d, debug)
    t = vty(V, E)
    lines = test_header(n)
    lines.append("    func mg%03d()%s {" % (n, " throws" if kind in (M, DM) else ""))
    lines.append("        // %s" % CELLS[n][3])
    if len(E) == 17:
        lines.append("        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: Array(repeating: UndirectedEdge(0, 1), count: 17))")
    else:
        lines.append("        " + construct(kind, V, E, t, mutable=False))
    lines.append("        #expect(graph.description == %s)" % swift_string(d))
    lines.append("        #expect(String(describing: graph) == %s)" % swift_string(d))
    lines.append("        #expect(graph.debugDescription == %s)" % swift_string(debug))
    lines.append("        #expect(String(reflecting: graph) == %s)" % swift_string(debug))
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Conversion rows (MG-160 – MG-178)
# ---------------------------------------------------------------------------------------------

def conversion_tests():
    out = []
    n = 160
    conv = [
        (P, [3], [(0, 1), (1, 0), (1, 1), (1, 1), (1, 2)], ()),
        (P, [], [(1, 0), (0, 1)], ()),
        (P, [], [(0, 1), (1, 2), (0, 1), (2, 0)], (("rmAt", 0),)),
        (DP, [], [(0, 1), (1, 0), (0, 1), (0, 0), (0, 0)], ()),
        (M, [], [(0, 1), (0, 1), (2, 1)], ()),
        (DM, [2], [(0, 1), (0, 1)], ()),
    ]
    for kind, V, E, ops in conv:
        g = model(kind, V, E, ops)
        simple = ref.collapse(g)
        assert cell(n) == simple.state(), n
        t = vty(V, E)
        target = "AdjacencyList" if g.directed else "UndirectedAdjacencyList"
        lines = test_header(n)
        lines.append("    func mg%03d()%s {" % (n, " throws" if kind in (M, DM) else ""))
        lines.append("        // %s" % CELLS[n][3])
        lines.append("        " + construct(kind, V, E, t, mutable=bool(ops)))
        for op in ops:
            lines.append("        graph.remove(edgeAt: %d)" % op[1])
        lines.append("        let simple = %s(graph)" % target)
        lines += state_lines(simple, var="simple", t=t, pairs=False)
        # Each pair once, as `contains(edge:)` on the multigraph says.
        lines.append("        #expect(Set(simple.edges) == Set(graph.edges))")
        lines.append("    }")
        out.append(lines)
        n += 1

    # MG-166: Pseudograph(ual)
    ual = ref.new("UndirectedAdjacencyList")
    for a, b in [(0, 1), (0, 2), (0, 3), (1, 2)]:
        ual.insert_edge(a, b)
    ual.remove_edge(0, 1)
    pg = ref.copy_generic(ual, P)
    assert cell(n) == pg.state() and ual.state() in CELLS[n][3]
    lines = test_header(n)
    lines.append("    func mg%03d() {" % n)
    lines.append("        // %s" % CELLS[n][3])
    lines.append("        var list = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2)])")
    lines.append("        list.remove(edge: UndirectedEdge(0, 1))")
    lines.append("        // The simple list's own rows, which the conversion does not keep.")
    lines += state_lines(ual, var="list", t="Int", pairs=False)
    lines.append("        let graph = Pseudograph(list)")
    lines += state_lines(pg, t="Int")
    lines.append("        #expect(UndirectedAdjacencyList(graph) == list)")
    lines.append("    }")
    out.append(lines)
    n += 1

    # MG-167: DirectedPseudograph(adjacencyList)
    al = ref.new("AdjacencyList")
    for a, b in [(0, 1), (1, 1), (1, 0), (2, 1)]:
        al.insert_edge(a, b)
    al.remove_edge(0, 1)
    dp = ref.copy_generic(al, DP)
    assert cell(n) == dp.state() and al.state() in CELLS[n][3]
    lines = test_header(n)
    lines.append("    func mg%03d() {" % n)
    lines.append("        // %s" % CELLS[n][3])
    lines.append("        var list = AdjacencyList<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1)])")
    lines.append("        list.remove(edge: DirectedEdge(from: 0, to: 1))")
    lines += state_lines(al, var="list", t="Int", pairs=False)
    lines.append("        let graph = DirectedPseudograph(list)")
    lines += state_lines(dp, t="Int")
    lines.append("        #expect(AdjacencyList(graph) == list)")
    lines.append("    }")
    out.append(lines)
    n += 1

    # MG-168: Multigraph(ual) with a loop
    assert cell(n) == "nil"
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        let list = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])",
        "        #expect(Multigraph(list) == nil)",
        "    }"])
    n += 1

    # MG-169: Multigraph(ual) without loops
    ual = ref.new("UndirectedAdjacencyList"); ual.insert_edge(0, 1); ual.insert_edge(1, 2)
    m = ref.copy_generic(ual, M)
    assert cell(n) == m.state()
    out.append(test_header(n) + [
        "    func mg%03d() throws {" % n,
        "        // %s" % CELLS[n][3],
        "        let list = UndirectedAdjacencyList<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
        "        let graph = try #require(Multigraph(list))"] + state_lines(m, t="Int") + ["    }"])
    n += 1

    # MG-170: Multigraph(pseudograph), no loops
    g = model(P, [], [(0, 1), (0, 1), (1, 2)])
    m = ref.copy_generic(g, M)
    assert cell(n) == m.state()
    out.append(test_header(n) + [
        "    func mg%03d() throws {" % n,
        "        // %s" % CELLS[n][3],
        "        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
        "        let graph = try #require(Multigraph(pseudograph))"] + state_lines(m, t="Int") + [
        "        #expect(Pseudograph(graph) == pseudograph)",
        "    }"])
    n += 1

    # MG-171
    assert cell(n) == "nil"
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])",
        "        #expect(Multigraph(pseudograph) == nil)",
        "    }"])
    n += 1

    # MG-172: Pseudograph(multigraph)
    g = model(M, [7], [(0, 1), (0, 1)])
    p = ref.copy_generic(g, P)
    assert cell(n) == p.state()
    out.append(test_header(n) + [
        "    func mg%03d() throws {" % n,
        "        // %s" % CELLS[n][3],
        "        let multigraph = try #require(Multigraph<Int>(vertices: [7], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))",
        "        let graph = Pseudograph(multigraph)"] + state_lines(p, t="Int") + [
        "        #expect(Multigraph(graph) == multigraph)",
        "    }"])
    n += 1

    # MG-173: Pseudograph(digraph.undirected)
    g = model(DP, [], [(0, 1), (1, 0), (1, 1)])
    h = ref.copy_generic(g, P, edges=list(g.edges()))
    assert cell(n) == h.state()
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        let digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)])",
        "        let graph = Pseudograph(digraph.undirected)"] + state_lines(h, t="Int") + ["    }"])
    n += 1

    # MG-174: DirectedPseudograph(graph.directed)
    g = model(P, [], [(0, 1), (0, 1), (1, 1)])
    dirs = []
    for a, b in g.edges():
        dirs += [(a, b), (b, a)]
    h = ref.copy_generic(g, DP, edges=dirs)
    assert cell(n) == h.state()
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])",
        "        let graph = DirectedPseudograph(pseudograph.directed)"] + state_lines(h, t="Int") + ["    }"])
    n += 1

    # MG-175
    assert cell(n) == "nil"
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        let pseudograph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])",
        "        #expect(DirectedMultigraph(pseudograph.directed) == nil)",
        "        // Without the loop, each edge is two opposite arcs.",
        "        let loopless = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])",
        "        #expect(DirectedMultigraph(loopless.directed)?.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [0, 1], [1, 0]])",
        "    }"])
    n += 1

    # MG-176
    assert cell(n) == "nil"
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        let digraph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])",
        "        #expect(DirectedMultigraph(digraph) == nil)",
        "    }"])
    n += 1

    # MG-177
    g = model(DM, [], [(0, 1), (0, 1)])
    p = ref.copy_generic(g, DP)
    assert cell(n) == p.state()
    out.append(test_header(n) + [
        "    func mg%03d() throws {" % n,
        "        // %s" % CELLS[n][3],
        "        let multigraph = try #require(DirectedMultigraph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))",
        "        let graph = DirectedPseudograph(multigraph)"] + state_lines(p, t="Int") + [
        "        #expect(DirectedMultigraph(graph) == multigraph)",
        "    }"])
    n += 1

    # MG-178: Pseudograph(pseudograph)
    g = model(P, [], [(0, 1), (1, 2), (0, 1), (2, 2)], [("rmAt", 0)])
    assert cell(n) == g.state()
    out.append(test_header(n) + [
        "    func mg%03d() {" % n,
        "        // %s" % CELLS[n][3],
        "        var original = Pseudograph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 2)])",
        "        original.remove(edgeAt: 0)",
        "        let graph = Pseudograph(original)"] + state_lines(g, t="Int") + [
        "        #expect(graph == original)",
        "        // Through the generic initializer too, from a `some Graph` of the same type.",
        "        func copy(_ g: some Graph<Int>) -> Pseudograph<Int> { Pseudograph(g) }",
        "        let generic = copy(original)",
        "        for v in original.vertices {",
        "            #expect(Array(generic.neighbors(of: v)) == Array(original.neighbors(of: v)))",
        "            #expect(Array(generic.incidentEdges(of: v)) == Array(original.incidentEdges(of: v)))",
        "        }",
        "    }"])
    n += 1
    assert n == 179
    return out


# ---------------------------------------------------------------------------------------------
# Trap rows (MG-179 – MG-192)
# ---------------------------------------------------------------------------------------------
TRAPS = {
    179: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "_ = graph.degree(of: 5)"],
    180: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "_ = graph.neighbors(of: 5)"],
    181: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "_ = graph.incidentEdges(of: 5)"],
    182: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "_ = graph.vertexIndex(of: 5)"],
    183: ["let graph = Pseudograph<Int>(vertices: [2], edges: [UndirectedEdge(0, 1)])", "_ = graph.oppositeVertex(to: 2, acrossEdgeAt: 0)"],
    184: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "_ = graph.oppositeVertex(to: 0, acrossEdgeAt: 1)"],
    185: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "_ = graph.edges[1]"],
    186: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "_ = graph.source(ofEdgeAt: 1)"],
    187: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "_ = graph.successors(of: 5)"],
    188: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "_ = graph.predecessors(of: 5)"],
    189: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "_ = graph.inDegree(of: 5)"],
    190: ["var graph = Pseudograph<Int>()", "graph.reserveCapacity(vertexCount: -1, edgeCount: 0)"],
    191: ["var graph = DirectedMultigraph<Int>()", "graph.reserveCapacity(vertexCount: 0, edgeCount: -1)"],
    192: ["var graph = DirectedMultigraph<Int>(vertices: [0, 1])", "graph.insert(edge: DirectedEdge(from: 0, to: 1))", "graph.insert(edge: DirectedEdge(from: 0, to: 1))", "graph.remove(edgeAt: 2)"],
}
# The same calls, one step short of the precondition: they must not trap.
TRAP_CONTROLS = {
    179: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "#expect(graph.degree(of: 1) == 1)"],
    180: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "#expect(Array(graph.neighbors(of: 1)) == [0])"],
    181: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "#expect(Array(graph.incidentEdges(of: 1)) == [0])"],
    182: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "#expect(graph.vertexIndex(of: 1) == 1)"],
    183: ["let graph = Pseudograph<Int>(vertices: [2], edges: [UndirectedEdge(0, 1)])", "#expect(graph.oppositeVertex(to: 1, acrossEdgeAt: 0) == 0)"],
    184: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "#expect(graph.oppositeVertex(to: 0, acrossEdgeAt: 0) == 1)"],
    185: ["let graph = Pseudograph<Int>(edges: [UndirectedEdge(0, 1)])", "#expect([graph.edges[0].u, graph.edges[0].v] == [0, 1])"],
    186: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "#expect(graph.source(ofEdgeAt: 0) == 0)", "#expect(graph.target(ofEdgeAt: 0) == 1)"],
    187: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "#expect(Array(graph.successors(of: 0)) == [1])"],
    188: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "#expect(Array(graph.predecessors(of: 1)) == [0])"],
    189: ["let graph = DirectedPseudograph<Int>(edges: [DirectedEdge(from: 0, to: 1)])", "#expect(graph.inDegree(of: 1) == 1)"],
    190: ["var graph = Pseudograph<Int>()", "graph.reserveCapacity(vertexCount: 0, edgeCount: 0)", "#expect(graph.vertexCount == 0)"],
    191: ["var graph = DirectedMultigraph<Int>()", "graph.reserveCapacity(vertexCount: 0, edgeCount: 0)", "#expect(graph.edgeCount == 0)"],
    192: ["var graph = DirectedMultigraph<Int>(vertices: [0, 1])", "graph.insert(edge: DirectedEdge(from: 0, to: 1))", "graph.insert(edge: DirectedEdge(from: 0, to: 1))", "#expect(graph.remove(edgeAt: 1) == DirectedEdge(from: 0, to: 1))"],
}


def trap_row_test(n):
    assert cell(n) == "trap"
    lines = test_header(n)
    lines.append("    func mg%03d() async {" % n)
    lines.append("        // %s → trap" % CELLS[n][3])
    lines.append("        await #expect(processExitsWith: .failure) {")
    for l in TRAPS[n]:
        lines.append("            " + l)
    lines.append("        }")
    lines.append("        // One step short of the precondition: no trap.")
    for l in TRAP_CONTROLS[n]:
        lines.append("        " + l)
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

FILES = [
    ("MultigraphConstructionTests.swift", "Multigraphs construction", range(1, 15),
     "Construction (catalog MG-001 – MG-014): `init(vertices:edges:)` on the four types, listed vertices\n"
     "// first (a repeat once), then endpoints in order of first appearance, then every edge at positions\n"
     "// 0, 1, … in its given orientation; the multigraphs' failable initializers returning nil on a\n"
     "// self-loop; the builder."),
    ("MultigraphQueryTests.swift", "Multigraphs queries: copies, loops, degrees, rows", range(15, 47),
     "Queries (catalog MG-015 – MG-046, without the trap rows MG-032 – MG-034, MG-039, MG-040, which are\n"
     "// in MultigraphPreconditionTests.swift): `edges(between:and:)` / `edges(from:to:)` oldest copy\n"
     "// first, `edgeCount(between:and:)`, `contains(edge:)` (false, never a trap, for a non-vertex),\n"
     "// self-loops twice in an undirected row and once in each directed row, degrees counting copies and\n"
     "// a loop twice, and the rows of a freshly built graph (each edge appended at u, then at v)."),
    ("MultigraphInsertionTests.swift", "Multigraphs insertion", range(47, 55),
     "Insertion (catalog MG-047 – MG-054): `insert(edge:)` always adds a copy and returns its position,\n"
     "// the old `edgeCount`; `insert(_:)` inserts a vertex once."),
    ("MultigraphEdgeRemovalTests.swift", "Multigraphs edge removal", range(55, 90),
     "Edge removal (catalog MG-055 – MG-089, without the trap rows MG-075 – MG-077, MG-080, which are in\n"
     "// MultigraphPreconditionTests.swift): `remove(edge:)` removes the newest copy and returns it in its\n"
     "// stored orientation (nil, without a change, for an absent pair); `remove(edgeAt:)` removes one\n"
     "// copy; `removeAllEdges(between:and:)` / `(from:to:)` is repeated `remove(edge:)`. The last edge\n"
     "// moves into the hole, and in each row the last entry moves into the hole (for an undirected\n"
     "// self-loop the later end goes first)."),
    ("MultigraphVertexRemovalTests.swift", "Multigraphs vertex removal", range(90, 105),
     "Vertex removal (catalog MG-090 – MG-104): the vertex's edges are detached last row entry first\n"
     "// (copies and loops included), then the last slot moves into its place, renamed in records, rows\n"
     "// and parallel classes, whose insertion order survives."),
    ("MultigraphSequenceTests.swift", "Multigraphs mutation sequences", range(105, 115),
     "Mutation sequences (catalog MG-105 – MG-114): insertions and removals interleaved, with every\n"
     "// intermediate result as ref.py's model gives it."),
    ("MultigraphEqualityTests.swift", "Multigraphs equality", range(115, 129),
     "Equality and hashing (catalog MG-115 – MG-128): equal vertex sets and equal edge multisets (each\n"
     "// edge with the same number of copies; orientation ignored for the undirected types). Vertex\n"
     "// order, positions, rows and class order do not matter."),
    ("MultigraphCodableTests.swift", "Multigraphs Codable", range(129, 154),
     "Codable (catalog MG-129 – MG-153): `{\"vertices\": […], \"edges\": [u0, v0, u1, v1, …]}`, the simple\n"
     "// lists' format. Encoding is checked byte for byte (with sorted keys); decoding keeps vertex order\n"
     "// and positions and rebuilds rows in position order. Corrupt payloads throw `DecodingError` with\n"
     "// the catalog's case and message."),
    ("MultigraphDescriptionTests.swift", "Multigraphs descriptions", range(154, 160),
     "Descriptions (catalog MG-154 – MG-159): `description` is the shared form, at most 16 items of each,\n"
     "// then `…`; `debugDescription` names the type and the counts."),
    ("MultigraphConversionTests.swift", "Multigraphs conversions", range(160, 179),
     "Conversions (catalog MG-160 – MG-178): to the simple lists (each pair keeps its first copy by\n"
     "// position, in its orientation), from them (vertex order and positions kept, rows rebuilt in\n"
     "// position order), between the multigraphs and the pseudographs, and through `.undirected` /\n"
     "// `.directed`."),
    ("MultigraphPreconditionTests.swift", "Multigraphs preconditions", None,
     "Preconditions (catalog MG-032 – MG-034, MG-039, MG-040, MG-075 – MG-077, MG-080, MG-179 – MG-192):\n"
     "// each trapping call runs in a child process (exit test). The same setup then runs in this process\n"
     "// one step short of the precondition, so the trap is the call's and not the setup's."),
]

TRAP_IDS = [32, 33, 34, 39, 40, 75, 76, 77, 80] + list(range(179, 193))


def write(fname, suite, ids, comment):
    if ids is None:
        ids = TRAP_IDS
    body = []
    needs_foundation = fname == "MultigraphCodableTests.swift"
    needs_al = fname == "MultigraphConversionTests.swift"
    tests = []
    for n in ids:
        if n in TRAP_IDS and fname != "MultigraphPreconditionTests.swift":
            continue
        if n in CASE_ROWS:
            tests.append(trap_case_test(n) if is_trap(n) else case_test(n))
        elif 115 <= n <= 128:
            tests.append(equality_test(n, EQS[n - 115]))
        elif 129 <= n <= 136:
            tests.append(trip_test(n, TRIPS[n - 129]))
        elif 137 <= n <= 153:
            tests.append(corrupt_test(n, CORRUPT[n - 137]))
        elif 154 <= n <= 159:
            tests.append(description_test(n, DESCS[n - 154]))
        elif 179 <= n <= 192:
            tests.append(trap_row_test(n))
    if fname == "MultigraphConversionTests.swift":
        tests = conversion_tests()
    tags = ', .tags(.precondition)' if fname == "MultigraphPreconditionTests.swift" else ""
    head = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    imports = []
    if needs_al or fname == "MultigraphCodableTests.swift":
        imports.append("import AdjacencyListModule")
    if needs_foundation:
        imports.append("import Foundation")
    imports += ["import GraphProtocols", "import Multigraphs", "import Testing"]
    if "precondition" in tags or fname in ("MultigraphEqualityTests.swift", "MultigraphCodableTests.swift"):
        imports.append("import GrafluentTestSupport")
    imports.sort()
    out = head + imports + ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    for i, t in enumerate(tests):
        if i:
            out.append("")
        out += t
    out.append("}")
    text = "\n".join(out) + "\n"
    # Tags are spelled `.precondition` etc. inside `.tags(...)`.
    with open(os.path.join(OUT, fname), "w") as f:
        f.write(text)
    return len(tests)


total = 0
for fname, suite, ids, comment in FILES:
    k = write(fname, suite, ids, comment)
    print(fname, k)
    total += k
print("total", total)
assert total == 192
