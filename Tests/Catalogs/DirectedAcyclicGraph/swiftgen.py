"""Writes the catalog-row test files of Tests/DirectedAcyclicGraphTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/DirectedAcyclicGraph/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/DirectedAcyclicGraphTests

First checks that ref.py's model reproduces cases.md byte for byte. Then it re-runs every row one call
at a time on ref.py's port of the wrapper over its port of the base, checking the laws after every
call, asserts that each value matches its catalog cell, and writes one @Test per row. Each call's
result is checked. After a mutation that another mutation follows, the test checks the order, the
vertices and the edges with their positions. The final state is written out in full: the order, every
vertex's place three ways, every row by vertex (out and in, with positions), the `safe:` rows of a
vertex and of a non-vertex, every position's ends, and the base. A rejected edge's witness is
Traversal's `bidirectionalShortestPath(from: target, to: source)`; the test checks that it is a genuine
path of the graph and one of the shortest paths the cell lists. Hand-written exit tests spliced into
the precondition file: extra_traps.swift.
"""
import copy
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "DirectedAcyclicGraphTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
SPEC, RAW = {}, {}
_case, _raw = ref.case, ref.raw


def _rec_case(group, title, kind, V, E, ops=(), note=None):
    SPEC[len(ref.ROWS) + 1] = (kind, list(V), list(E), list(ops))
    _case(group, title, kind, V, E, ops, note)


def _rec_raw(group, title, inp, exp):
    RAW[len(ref.ROWS) + 1] = (inp, exp)
    _raw(group, title, inp, exp)


ref.case, ref.raw = _rec_case, _rec_raw
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| DAG-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][4:])] = parts
N = len(CELLS)
assert sorted(list(SPEC) + list(RAW)) == list(range(1, N + 1))


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3]
def cell(n): return CELLS[n][4]
def is_trap(n): return "**trap**" in cell(n)


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------
BASE = {"AL": "AdjacencyList", "DP": "DirectedPseudograph", "SG": "StableDirectedGraph"}
MUTATING = {"insert", "edge", "safe", "remove", "removeEdge", "removeAt", "removeAll", "removeAllEdges"}


def vtype(V, E, ops):
    every = list(V) + [x for e in E for x in e] + [x for o in ops if o[0] != "equals" for x in o[1:]]
    return "String" if any(isinstance(x, str) for x in every) else "Int"


def lit(x): return json.dumps(x, ensure_ascii=False) if isinstance(x, str) else str(x)


def arr(xs, t): return "[" + ", ".join(lit(x) for x in xs) + "]" if xs else "[] as [%s]" % t


def arr2(xss, t): return "[" + ", ".join(arr(xs, t) for xs in xss) + "]" if xss else "[] as [[%s]]" % t


def dedge(a, b): return "DirectedEdge(from: %s, to: %s)" % (lit(a), lit(b))


def dedges(E, t): return "[" + ", ".join(dedge(a, b) for a, b in E) + "]" if E else "[] as [DirectedEdge<%s>]" % t


def dag_type(kind, t): return "DirectedAcyclicGraph<%s<%s>>" % (BASE[kind], t)


def construct(kind, V, E, t, mutable, var="graph", bang=False):
    expr = "%s(vertices: %s, edges: %s)" % (dag_type(kind, t), arr(V, t), dedges(E, t))
    if bang:
        return "%s %s = %s!" % ("var" if mutable else "let", var, expr)
    return "%s %s = try #require(%s)" % ("var" if mutable else "let", var, expr)


def non_vertex(g, t):
    vs = [g.b.vertex(k) for k in g.b.keys()]
    if t == "String":
        return lit("absent")
    return str(max([x for x in vs if isinstance(x, int)], default=0) + 100)


# ---------------------------------------------------------------------------------------------
# State: everything the model knows, written out
# ---------------------------------------------------------------------------------------------

def state(g, t, var="graph", short=False, ind="        "):
    keys = g.b.keys()
    V = [g.b.vertex(k) for k in keys]
    E = g.b.edges()
    order = g.topological_order()
    ps = [p for p, _, _ in E]
    arcs = [(g.b.vertex(s), g.b.vertex(tt)) for _, s, tt in E]
    out = ["#expect(Array(%s.topologicalOrder) == %s)" % (var, arr(order, t)),
           "#expect(Array(%s.vertices) == %s)" % (var, arr(V, t)),
           "#expect(Array(%s.edges.indices) == %s)" % (var, arr(ps, "Int")),
           "#expect(Array(%s.edges) == %s)" % (var, dedges(arcs, t))]
    if short:
        return [ind + l for l in out]
    n = len(V)
    out += ["#expect(%s.vertexCount == %d && %s.edgeCount == %d)" % (var, n, var, len(E)),
            "#expect(%s.topologicalOrder.count == %d && %s.topologicalOrder.indices == 0 ..< %d)" % (var, n, var, n)]
    if E:
        out.append("#expect(%s.edges.indices.map { [%s.source(ofEdgeAt: $0), %s.target(ofEdgeAt: $0)] } == %s)" % (
            var, var, var, arr2([list(a) for a in arcs], t)))
    out.append("#expect(Array(%s.base.vertices) == %s && Array(%s.base.edges) == %s)" % (var, arr(V, t), var, dedges(arcs, t)))
    for k in keys:
        v = g.b.vertex(k)
        x = lit(v)
        i = g.ord[k]
        o, inn = g.b.out_row(k), g.b.in_row(k)
        succ = [g.b.vertex(tt) for tt, _ in o]
        pred = [g.b.vertex(s) for s, _ in inn]
        op = [p for _, p in o]
        ip = [p for _, p in inn]
        out.append("#expect(%s.topologicalPosition(of: %s) == %d && %s.topologicalPosition(safe: %s) == %d && %s.topologicalOrder.firstIndex(of: %s) == %d)" % (
            var, x, i, var, x, i, var, x, i))
        out.append("#expect(Array(%s.successors(of: %s)) == %s && Array(%s.outEdges(of: %s)) == %s && %s.outDegree(of: %s) == %d)" % (
            var, x, arr(succ, t), var, x, arr(op, "Int"), var, x, len(o)))
        out.append("#expect(Array(%s.predecessors(of: %s)) == %s && Array(%s.inEdges(of: %s)) == %s && %s.inDegree(of: %s) == %d)" % (
            var, x, arr(pred, t), var, x, arr(ip, "Int"), var, x, len(inn)))
        out.append("#expect(%s.successors(safe: %s).map { Array($0) } == %s && %s.outEdges(safe: %s).map { Array($0) } == %s && %s.outDegree(safe: %s) == %d)" % (
            var, x, arr(succ, t), var, x, arr(op, "Int"), var, x, len(o)))
        out.append("#expect(%s.predecessors(safe: %s).map { Array($0) } == %s && %s.inEdges(safe: %s).map { Array($0) } == %s && %s.inDegree(safe: %s) == %d)" % (
            var, x, arr(pred, t), var, x, arr(ip, "Int"), var, x, len(inn)))
    y = non_vertex(g, t)
    out.append("#expect(!%s.contains(%s) && %s.topologicalPosition(safe: %s) == nil && %s.topologicalOrder.firstIndex(of: %s) == nil)" % (var, y, var, y, var, y))
    out.append("#expect(%s.successors(safe: %s) == nil && %s.predecessors(safe: %s) == nil && %s.outEdges(safe: %s) == nil)" % (var, y, var, y, var, y))
    out.append("#expect(%s.inEdges(safe: %s) == nil && %s.outDegree(safe: %s) == nil && %s.inDegree(safe: %s) == nil)" % (var, y, var, y, var, y))
    return [ind + l for l in out]


# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------

def call_lines(g, kind, t, op, k, ind="        "):
    """The call's result on the model, its catalog text, and the Swift lines that check it."""
    r = ref.apply(g, op)
    ref.check_laws(g)
    shown = ref.show_result(r)
    name = op[0]
    a = op[1:]

    def ex(text): return [ind + "#expect(%s)" % text]

    if name == "insert":
        return shown, [ind + "let inserted%d = graph.insert(%s)" % (k, lit(a[0])),
                       ind + "#expect(inserted%d.inserted == %s && inserted%d.memberAfterInsert == %s)" % (
                           k, "true" if r[0] else "false", k, lit(r[1]))]
    if name in ("edge", "safe"):
        label = "edge" if name == "edge" else "safe"
        return shown, ex("graph.insert(%s: %s) == %s" % (label, dedge(*a), "nil" if r is None else r))
    if name == "remove":
        return shown, ex("graph.remove(%s) == %s" % (lit(a[0]), "nil" if r is None else lit(r)))
    if name == "removeEdge":
        return shown, ex("graph.remove(edge: %s) == %s" % (dedge(*a), "nil" if r is None else dedge(*r)))
    if name == "removeAt":
        return shown, ex("graph.remove(edgeAt: %d) == %s" % (a[0], dedge(*r)))
    if name == "removeAll":
        return shown, [ind + "graph.removeAll()"]
    if name == "removeAllEdges":
        return shown, [ind + "graph.removeAllEdges()"]
    if name == "position":
        return shown, ex("graph.topologicalPosition(of: %s) == %d" % (lit(a[0]), r))
    if name == "positionSafe":
        return shown, ex("graph.topologicalPosition(safe: %s) == %s" % (lit(a[0]), "nil" if r is None else r))
    if name == "orderAt":
        return shown, ex("graph.topologicalOrder[%d] == %s" % (a[0], r))
    if name == "hasPath":
        b = "true" if r else "false"
        return shown, ex("graph.hasPath(from: %s, to: %s) == %s" % (lit(a[0]), lit(a[1]), b)) + \
            ex("graph.base.hasPath(from: %s, to: %s) == %s" % (lit(a[0]), lit(a[1]), b))
    if name == "witness":
        src, dst = a
        paths = r[1]
        assert paths, "every catalog witness exists"
        w = "witness%d" % k
        opts = "[" + ", ".join("(%s, %s)" % (arr(vs, t), arr(ps, "Int")) for vs, ps in paths) + "]"
        return shown, [
            ind + "let %s = try #require(graph.bidirectionalShortestPath(from: %s, to: %s))" % (w, lit(src), lit(dst)),
            ind + "#expect(%s.source == %s && %s.target == %s && %s.vertices.count == %s.edges.count + 1)" % (w, lit(src), w, lit(dst), w, w),
            ind + "#expect(%s.edges.indices.allSatisfy { graph.source(ofEdgeAt: %s.edges[$0]) == %s.vertices[$0] && graph.target(ofEdgeAt: %s.edges[$0]) == %s.vertices[$0 + 1] })" % (w, w, w, w, w),
            ind + "let shortest%d: [([%s], [Int])] = %s" % (k, t, opts),
            ind + "#expect(shortest%d.contains { $0.0 == %s.vertices && $0.1 == %s.edges })" % (k, w, w)]
    if name in ("closure", "reduction"):
        var = "closure" if name == "closure" else "reduction"
        method = "transitiveClosure" if name == "closure" else "transitiveReduction"
        h = r[1]
        ref.check_laws(h)
        return shown, [ind + "let %s%d = graph.%s()" % (var, k, method)] + state(h, t, var="%s%d" % (var, k), ind=ind)
    if name == "longest":
        if r is None:
            return shown, ex("graph.longestPath() == nil")
        return shown, [ind + "let longest%d = try #require(graph.longestPath())" % k,
                       ind + "#expect(longest%d.vertices == %s && longest%d.edges == %s)" % (k, arr(r[1], t), k, arr(r[2], "Int"))]
    if name == "longestW":
        w = arr(a[0], "Int")
        if r is None:
            return shown, ex("graph.longestPath(weight: { (%s)[$0] }) == nil" % w)
        return shown, [ind + "let longest%d = try #require(graph.longestPath(weight: { %s[$0] }))" % (k, w),
                       ind + "#expect(longest%d.vertices == %s && longest%d.edges == %s)" % (k, arr(r[1], t), k, arr(r[2], "Int"))]
    if name == "dagSP":
        src, weights = a
        w = arr(weights, "Int")
        rows = r[1]
        st = {g.b.key(v): x for v, x in rows if x is not None}
        lines = [ind + "let weights%d = %s" % (k, w),
                 ind + "let tree%d = graph.dagShortestPaths(from: %s, weight: { weights%d[$0] })" % (k, lit(src), k),
                 ind + "// The same distances from any DirectedGraph, by a topological sort of the reachable part.",
                 ind + "let sorted%d = try #require(graph.base.dagShortestPaths(from: %s, weight: { weights%d[$0] }))" % (k, lit(src), k)]
        for v, x in rows:
            if x is None:
                lines += ex("tree%d.distance(to: %s) == nil && tree%d.path(to: %s) == nil && sorted%d.distance(to: %s) == nil" % (k, lit(v), k, lit(v), k, lit(v)))
            else:
                ps = ref.tree_path(g, st, g.b.key(v))
                lines += ex("tree%d.distance(to: %s) == %d && tree%d.path(to: %s)?.edges == %s && sorted%d.distance(to: %s) == %d" % (
                    k, lit(v), x[0], k, lit(v), arr(ps, "Int"), k, lit(v), x[0]))
        return shown, lines
    if name == "equals":
        kb, Vb, Eb = a
        other = "other%d" % k
        lines = [ind + construct(kb, Vb, Eb, t, False, var=other)]
        if r:
            lines += ex("graph == %s && %s == graph" % (other, other))
            lines += ex("graph.hashValue == %s.hashValue" % other)
            lines.append(ind + "// Equal although the orders differ.")
            lines += ex("Array(graph.topologicalOrder) == %s && Array(%s.topologicalOrder) == %s" % (
                arr(g.topological_order(), t), other, arr(ref.DAG.build(kb, Vb, Eb).topological_order(), t)))
        else:
            lines += ex("graph != %s && %s != graph" % (other, other))
        return shown, lines
    raise ValueError(op)


def child_call(op):
    name, *a = op
    return {
        "removeAt": lambda: "_ = graph.remove(edgeAt: %d)" % a[0],
        "position": lambda: "_ = graph.topologicalPosition(of: %s)" % lit(a[0]),
        "orderAt": lambda: "_ = graph.topologicalOrder[%d]" % a[0],
        "hasPath": lambda: "_ = graph.hasPath(from: %s, to: %s)" % (lit(a[0]), lit(a[1])),
    }[name]()


def setup_call(op):
    name, *a = op
    return {
        "removeAt": lambda: "_ = graph.remove(edgeAt: %d)" % a[0],
    }[name]()


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def header(n, tags=()):
    return ['    @Test("DAG-%03d %s"%s)' % (n, title(n), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def alternatives(n, kind, V, E, t, g):
    """The other initializers, on the construction rows they fit: the same state (or nil)."""
    T = dag_type(kind, t)
    B = "%s<%s>" % (BASE[kind], t)
    other = "StableDirectedGraph" if kind == "DP" else "DirectedPseudograph"
    alts = []
    if not V and not E:
        alts.append(("%s()" % T, False))
    if not E:
        alts.append(("%s(vertices: %s)" % (T, arr(V, t)), False))
    if not V:
        alts.append(("%s(edges: %s)" % (T, dedges(E, t)), True))
    alts.append(("%s(%s(vertices: %s, edges: %s))" % (T, B, arr(V, t), dedges(E, t)), True))
    alts.append(("%s(%s<%s>(vertices: %s, edges: %s))" % (T, other, t, arr(V, t), dedges(E, t)), True))
    builder = None if not V and not E else ["%s {" % T] + ["    " + lit(v) for v in V] + ["    " + dedge(a, b) for a, b in E] + ["}"]
    out = []
    if g is None:
        out.append("        // Every other initializer that fits is nil too.")
        for a, failable in alts:
            if failable:
                out.append("        #expect(%s == nil)" % a)
        out.append("        let built = " + builder[0])
        out += ["        " + l for l in builder[1:]]
        out.append("        #expect(built == nil)")
        return out
    out.append("        // The other initializers give the same state.")
    for a, failable in alts + ([(builder, True)] if builder else []):
        out.append("        do {")
        if isinstance(a, list):
            out.append("            let built = try #require(" + a[0])
            out += ["            " + l for l in a[1:-1]]
            out.append("            " + a[-1] + ")")
        elif failable:
            out.append("            let built = try #require(%s)" % a)
        else:
            out.append("            let built = %s" % a)
        out += state(g, t, var="built", short=True, ind="            ")
        out.append("            #expect(built == graph && built.base == graph.base)")
        out.append("        }")
    return out


def row_test(n):
    kind, V, E, ops = SPEC[n]
    t = vtype(V, E, ops)
    g = ref.DAG.build(kind, V, E)
    mut = any(o[0] in MUTATING for o in ops)
    lines = header(n)
    lines.append("    func dag%03d() throws {" % n)
    lines.append("        // %s" % inp(n))
    if g is None:
        assert cell(n) == "nil" and not ops
        lines.append("        #expect(%s(vertices: %s, edges: %s) == nil)" % (dag_type(kind, t), arr(V, t), dedges(E, t)))
        lines += alternatives(n, kind, V, E, t, None)
        lines.append("    }")
        return lines
    ref.check_laws(g)
    lines.append("        " + construct(kind, V, E, t, mut))
    shown = []
    for i, op in enumerate(ops):
        r, ls = call_lines(g, kind, t, op, i + 1)
        shown.append(r)
        lines += ls
        if op[0] in MUTATING and any(x[0] in MUTATING for x in ops[i + 1:]):
            lines.append("        // After %s." % ref.show_op(op))
            lines += state(g, t, short=True)
    exp = ("; ".join(shown) + " ⇒ " if shown else "") + ref.show_state(g)
    assert exp == cell(n), (n, exp, cell(n))
    lines.append("        // Final state.")
    lines += state(g, t)
    if group(n) == "Construction":
        lines += alternatives(n, kind, V, E, t, g)
    lines.append("    }")
    return lines


def trap_test(n):
    kind, V, E, ops = SPEC[n]
    t = vtype(V, E, ops)
    *setup, last = ops
    g = ref.DAG.build(kind, V, E)
    for op in setup:
        ref.apply(g, op)
    probe = copy.deepcopy(g)
    try:
        ref.apply(probe, last)
        raise AssertionError("no trap: %d" % n)
    except ref.Trap:
        pass
    mut = bool(setup) or last[0] in MUTATING
    lines = header(n)
    lines.append("    func dag%03d() async throws {" % n)
    lines.append("        // %s → %s" % (inp(n), cell(n)))
    lines.append("        await #expect(processExitsWith: .failure) {")
    lines.append("            " + construct(kind, V, E, t, mut, bang=True))
    for op in setup:
        lines.append("            " + setup_call(op))
    lines.append("            " + child_call(last))
    lines.append("        }")
    lines.append("        // Without the call: the state the call would apply to.")
    lines.append("        " + construct(kind, V, E, t, bool(setup)))
    g2 = ref.DAG.build(kind, V, E)
    shown = []
    for i, op in enumerate(setup):
        r, ls = call_lines(g2, kind, t, op, i + 1)
        shown.append(r)
        lines += ls
    exp = "; ".join(shown + ["**trap**"])
    assert exp == cell(n), (n, exp, cell(n))
    lines += state(g2, t)
    lines.append("    }")
    return lines


def codable_test(n):
    text, exp = RAW[n]
    kind = {v: k for k, v in BASE.items()}[text.split(";")[0]]
    T = "DirectedAcyclicGraph<%s<Int>>" % BASE[kind]
    lines = header(n, [".conformance"])
    if 'decode {"base"' in text:
        return lines + hostile_test(n, text, exp, T)
    lines.append("    func dag%03d() throws {" % n)
    lines.append("        // %s → %s" % (text, exp))
    m = re.match(r"\w+; decode \{base: V \[(.*?)\]; E \[(.*?)\]((?: / remove\(\d+\))*), order: \[(.*?)\]\}$", text)
    V = [int(x) for x in m.group(1).split(", ") if x]
    E = [tuple(int(y) for y in x.split("→")) for x in m.group(2).split(", ") if x]
    removed = [int(x) for x in re.findall(r"remove\((\d+)\)", m.group(3))]
    order = [int(x) for x in m.group(4).split(", ") if x]
    r = ref.decode(kind, V, E, order, removed)
    built = "%s<Int>(vertices: %s, edges: %s)" % (BASE[kind], arr(V, "Int"), dedges(E, "Int"))
    if removed:
        lines.append("        var baseGraph = " + built)
        lines += ["        _ = baseGraph.remove(%d)" % x for x in removed]
        lines.append("        let base = String(decoding: try JSONEncoder().encode(baseGraph), as: UTF8.self)")
    else:
        lines.append("        let base = String(decoding: try JSONEncoder().encode(%s), as: UTF8.self)" % built)
    lines.append('        let payload = Data(#"{"base": \\#(base), "order": %s}"#.utf8)' % arr(order, "Int").replace(" as [Int]", ""))
    if isinstance(r, str):
        assert r == exp
        lines += ["        do {",
                  "            let decoded = try JSONDecoder().decode(%s.self, from: payload)" % T,
                  "            Issue.record(\"decoded \\(decoded)\")",
                  "        } catch DecodingError.dataCorrupted {",
                  "        } catch {",
                  "            Issue.record(\"unexpected error \\(error)\")",
                  "        }"]
        g = ref.DAG.build(kind, V, E)
        if g is None:
            lines += ["        // The base itself has a cycle, so no order decodes.",
                      "        let valid = Data(#\"{\"base\": \\#(base), \"order\": %s}\"#.utf8)" % arr(list(range(len(V))), "Int").replace(" as [Int]", ""),
                      "        #expect(throws: DecodingError.self) { try JSONDecoder().decode(%s.self, from: valid) }" % T,
                      "    }"]
            return lines
        for x in removed:
            g.remove_vertex(x)
        offsets = [g.b.keys().index(k) for k in g.order]
        lines.append("        // The same base with a valid order decodes.")
        lines.append("        let valid = Data(#\"{\"base\": \\#(base), \"order\": %s}\"#.utf8)" % ("[" + ", ".join(map(str, offsets)) + "]"))
        lines.append("        let graph = try JSONDecoder().decode(%s.self, from: valid)" % T)
        lines += state(g, "Int")
        lines.append("    }")
        return lines
    assert ref.show_state(r) == exp
    lines.append("        let graph = try JSONDecoder().decode(%s.self, from: payload)" % T)
    lines += state(r, "Int")
    lines.append("        // Encoding and decoding again keeps the order.")
    lines.append("        let again = try JSONDecoder().decode(%s.self, from: try JSONEncoder().encode(graph))" % T)
    lines += state(r, "Int", var="again", short=True)
    lines.append("        #expect(again == graph)")
    lines.append("    }")
    return lines


def hostile_test(n, text, exp, T):
    """A payload whose one vertex sits at a far position: the key table must start at its page."""
    payload = text.split("decode ", 1)[1]
    g = ref.decode_stable([7], [ref.HOSTILE], ref.HOSTILE + 1, [0])
    assert ref.show_state(g) == exp
    lines = ["    func dag%03d() throws {" % n,
             "        // %s → %s" % (text, exp),
             "        // Before the key table started at the first live page, this allocated a table entry for",
             "        // every page below the position: 2⁴⁰ words.",
             '        let payload = Data(#"%s"#.utf8)' % payload,
             "        var graph = try JSONDecoder().decode(%s.self, from: payload)" % T]
    lines += state(g, "Int")
    lines += ["        let again = try JSONDecoder().decode(%s.self, from: try JSONEncoder().encode(graph))" % T,
              "        #expect(again == graph && Array(again.topologicalOrder) == [7])",
              "        // Inserting next to it, before it, and removing it all work from that one page.",
              "        #expect(graph.insert(edge: DirectedEdge(from: 7, to: 8)) == 0)",
              "        #expect(graph.insert(edge: DirectedEdge(from: 9, to: 7)) == 1)",
              "        #expect(Array(graph.topologicalOrder) == [9, 7, 8])",
              "        #expect(graph.base.vertexPosition(of: 9) == %d)" % (ref.HOSTILE + 2),
              "        #expect(graph.topologicalPosition(of: 8) == 2 && graph.insert(edge: DirectedEdge(from: 8, to: 9)) == nil)",
              "        #expect(graph.remove(7) == 7)",
              "        #expect(Array(graph.topologicalOrder) == [9, 8] && graph.topologicalPosition(of: 8) == 1)",
              "    }"]
    return lines


def test_for(n):
    if n in RAW:
        return codable_test(n)
    return trap_test(n) if is_trap(n) else row_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if group(n) in groups and not is_trap(n)]


def span(name):
    rows = [n for n in range(1, N + 1) if group(n) == name]
    return "DAG-%03d – DAG-%03d" % (rows[0], rows[-1])


TRAPS = [n for n in range(1, N + 1) if is_trap(n)]
G = {name: ids(name) for name in ("Construction", "Insertion", "Reordering", "Cycle witness", "insert(safe:)", "Removal",
                                  "Order queries", "Algorithms", "Codable")}
FILES = [
    ("DirectedAcyclicGraphConstructionTests.swift", "DirectedAcyclicGraph construction", G["Construction"],
     "Construction (catalog %s): the base is built as it builds itself, listed vertices first; the\n"
     "// initial order is Kahn's, FIFO, roots in `vertices` order; a cycle or a self-loop gives nil; every\n"
     "// initializer that fits gives the same state." % span("Construction")),
    ("DirectedAcyclicGraphInsertionTests.swift", "DirectedAcyclicGraph insertion", G["Insertion"] + G["Reordering"],
     "Insertion and reordering (catalog %s, %s): a vertex is placed last; a forward edge\n"
     "// moves nothing; missing endpoints are inserted, source first; a backward edge moves the backward set\n"
     "// B and then the forward set F into their pooled places, and nothing else." % (span("Insertion"), span("Reordering"))),
    ("DirectedAcyclicGraphRejectionTests.swift", "DirectedAcyclicGraph rejection", G["Cycle witness"] + G["insert(safe:)"],
     "Rejected edges (catalog %s, %s): `insert(edge:)` and `insert(safe:)` return nil for an\n"
     "// edge that would close a cycle, a self-loop included, and change nothing; the witness is Traversal's\n"
     "// `bidirectionalShortestPath(from: target, to: source)`, checked as a genuine shortest path; `insert(safe:)`\n"
     "// also returns nil for a missing endpoint." % (span("Cycle witness"), span("insert(safe:)"))),
    ("DirectedAcyclicGraphRemovalTests.swift", "DirectedAcyclicGraph removal", G["Removal"],
     "Removal (catalog %s): removals keep the order; `remove(_:)` closes the gap and follows the\n"
     "// base's swap-remove; the resets." % span("Removal")),
    ("DirectedAcyclicGraphQueryTests.swift", "DirectedAcyclicGraph order queries and algorithms", G["Order queries"] + G["Algorithms"],
     "Order queries and algorithms (catalog %s, %s): `topologicalPosition`, the order's\n"
     "// subscript, the order-pruned `hasPath`, equality that ignores the order, `transitiveClosure()`,\n"
     "// `transitiveReduction()` and `longestPath()`." % (
         span("Order queries"),
         span("Algorithms"))),
    ("DirectedAcyclicGraphCodableTests.swift", "DirectedAcyclicGraph Codable", G["Codable"],
     "Codable (catalog %s): `{base, order}` with the order as offsets into `base.vertices`; a\n"
     "// round trip keeps the order; decoding rejects a cyclic base, an order that is not a permutation and an\n"
     "// edge going backward, as `DecodingError.dataCorrupted`." % span("Codable")),
    ("DirectedAcyclicGraphPreconditionTests.swift", "DirectedAcyclicGraph preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]
IMPORTS = {"AdjacencyListModule": "AdjacencyList<", "Multigraphs": "DirectedPseudograph",
           "StableGraphs": "StableDirectedGraph"}


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "DirectedAcyclicGraphPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["DirectedAcyclicGraphModule", "GraphProtocols", "Testing"]
    for module, needle in IMPORTS.items():
        if needle in text:
            imports.append(module)
    if "bidirectionalShortestPath(" in text or ".hasPath(" in text:
        imports.append("Traversal")
    if "dagShortestPaths(" in text:
        imports.append("ShortestPaths")
    if "JSONEncoder" in text:
        imports.append("Foundation")
    if ".tags(" in text or fname == "DirectedAcyclicGraphPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    if ".vertices ==" in text or "longestPath()" in text:
        imports.append("Walks")
    imports = sorted(set(imports), key=str.lower)
    tags = ", .tags(.precondition)" if fname == "DirectedAcyclicGraphPreconditionTests.swift" else ""
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rows, comment in FILES:
    k = write(fname, suite, rows, comment)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == N, rows_total
print("catalog rows", rows_total, "tests", total)
