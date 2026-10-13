"""Writes the catalog-row test files of Tests/SemiringsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with numpy==2.3.4 \
        python3 Tests/Catalogs/Semirings/swiftgen.py [--phase2] [OUT_DIR]
    # default OUT_DIR: Tests/SemiringsTests

First checks that ref.py's model reproduces cases.md byte for byte (every row recomputed, and
every algorithm row checked against NetworkX, scipy or brute force by ref.py), then writes one
@Test per row. The "Phase 2" rows (the last ones: `star`, `kleeneClosure`, `LogSemiring`, which the
library does not declare) are written to SemiringPhase2Tests.swift only with --phase2; without the
flag that file is removed.

Each row is written the way the catalog writes it: `S(value)` operands for the law and
arithmetic rows; for the algorithm rows a `DirectedPseudograph` (or a `Pseudograph` read through
`.directedView`) built from the listed edges in position order, `w` the raw weights by position, and
`weight: { S(w[$0]) }`. A tree row checks `distance(to:)`, `distance(toIndex:)`, `hasPath(to:)`
and `sources`, and every `path(to:)` by the definition: consecutive edges of the graph from a
source, whose ⊗-product is the distance, ending in `parentEdge(of:)`. A matrix row checks
`distance(from:to:)`, `distance(fromIndex:toIndex:)` and every `path(from:to:)` the same way.
Trap rows run the call in a child process (exit test), then the same setup without the fault in
this process. Hand-written exit tests spliced into the precondition file: extra_traps.swift.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
PHASE2 = "--phase2" in sys.argv
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.join(HERE, "..", "..", "SemiringsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
sys.setrecursionlimit(10000)
ref.define()
ref.number_rows()
for r in ref.ROWS:
    r.append(ref.evaluate(r[:6]))
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
ROWS = {int(r[0][3:]): r for r in ref.ROWS}
N = len(ROWS)
P2 = min(n for n, r in ROWS.items() if r[1].startswith("Phase 2"))
assert all(ROWS[n][1].startswith("Phase 2") for n in range(P2, N + 1))


def group(n): return ROWS[n][1]
def case(n): return ROWS[n][2]
def sname(n): return ROWS[n][3]
def inp(n): return ROWS[n][4]
def op(n): return ROWS[n][5]
def cell(n): return ROWS[n][6]
def is_trap(n): return cell(n).startswith("**trap**")
def sr(n): return ref.ALL[sname(n)]


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def scalar(s):
    return s.scalar


def lit(s, tok):
    """A catalog value token as a Swift literal of the scalar type."""
    tok = tok.strip()
    if tok == "—":
        return "nil"
    if ref.is_float(s):
        if tok == ".infinity":
            return "%s.infinity" % s.scalar
        if tok == "-.infinity":
            return "-%s.infinity" % s.scalar
    return tok


def vlit(s, v):
    if s is ref.LOG_D and v not in (ref.INF, -ref.INF):
        return repr(float(v))
    return lit(s, ref.fmt(s, v))


def type_base(s):
    return s.name.split("<")[0]


def split_list(text):
    assert text[0] == "[" and text[-1] == "]", text
    return [t.strip() for t in text[1:-1].split(",")]


def split_matrix(text):
    assert text[0] == "[" and text[-1] == "]", text
    return [[t.strip() for t in row.split(",")] for row in text[1:-1].split(";")]


def wrap(items, ind, per=12):
    """`[a, b, …]` over several lines when long."""
    if len(items) <= per:
        return "[" + ", ".join(items) + "]"
    lines = ["["]
    for i in range(0, len(items), per):
        lines.append(ind + "    " + ", ".join(items[i:i + per]) + ",")
    lines.append(ind + "]")
    return "\n".join(lines)


def swift_description(s, v):
    if s.scalar == "Bool":
        return "true" if v else "false"
    if ref.is_int(s):
        return str(v)
    if v == ref.INF:
        return "inf"
    if v == -ref.INF:
        return "-inf"
    return repr(float(v))


# ---------------------------------------------------------------------------------------------
# Graphs
# ---------------------------------------------------------------------------------------------

def graph_of(n):
    s = sr(n)
    gcell = inp(n).replace(":Z", f":{ref.fmt(s, s.zero)}").replace(":O", f":{ref.fmt(s, s.one)}")
    return ref.parse_graph(gcell, s)


def token(n):
    m = re.search(r"\b(ladder|grid)\(([\d,]+)\)", inp(n))
    return (m.group(1), [int(x) for x in m.group(2).split(",")]) if m else None


def graph_lines(n, ind):
    """Swift statements that build `graph` and `w` for row n; returns (lines, view, index_expr)."""
    s = sr(n)
    g = graph_of(n)
    sc = scalar(s)
    tok = token(n)
    out = []
    if tok:
        kind, a = tok
        out.append(ind + "var edges: [DirectedEdge<Int>] = []")
        if kind == "ladder":
            out += [ind + "for i in 0 ..< %d {" % a[0],
                    ind + "    edges += [DirectedEdge(from: 2 * i, to: 2 * i + 1), DirectedEdge(from: 2 * i, to: 2 * i + 2), DirectedEdge(from: 2 * i + 1, to: 2 * i + 2)]",
                    ind + "}"]
        else:
            r, c = a
            out += [ind + "for i in 0 ..< %d {" % r,
                    ind + "    for j in 0 ..< %d {" % c,
                    ind + "        if j + 1 < %d { edges.append(DirectedEdge(from: i * %d + j, to: i * %d + j + 1)) }" % (c, c, c),
                    ind + "        if i + 1 < %d { edges.append(DirectedEdge(from: i * %d + j, to: (i + 1) * %d + j)) }" % (r, c, c),
                    ind + "    }",
                    ind + "}"]
        assert all(w == 1 for _, _, w in g.edges)
        out.append(ind + "#expect(edges.count == %d)" % len(g.edges))
        out.append(ind + "let graph = DirectedPseudograph(vertices: 0 ..< %d, edges: edges)" % g.n)
        out.append(ind + "let w = [%s](repeating: 1, count: edges.count)" % sc)
        return out, "graph", "$0"
    if g.directed:
        es = ["DirectedEdge(from: %d, to: %d)" % (u, v) for u, v, _ in g.edges]
        out.append(ind + "let graph = DirectedPseudograph(vertices: 0 ..< %d, edges: %s)" % (g.n, wrap(es, ind, 4)))
        view, idx = "graph", "$0"
    else:
        es = ["UndirectedEdge(%d, %d)" % (u, v) for u, v, _ in g.edges]
        out.append(ind + "let graph = Pseudograph(vertices: 0 ..< %d, edges: %s)" % (g.n, wrap(es, ind, 6)))
        out.append(ind + "let directed = graph.directedView")
        view, idx = "directed", "$0.position"
    out.append(ind + "let w: [%s] = %s" % (sc, wrap([vlit(s, x) for _, _, x in g.edges], ind, 12)))
    return out, view, idx


def weight_closure(n, idx):
    return "{ %s(w[%s]) }" % (type_base(sr(n)), idx)


def call_parts(n):
    """(function, argument text in Swift, wrapped in DirectedAcyclicGraph)."""
    m = re.fullmatch(r"(?:DirectedAcyclicGraph\(g\)\.)?(\w+)\((.*)\)", op(n))
    fn, args = m.group(1), m.group(2)
    s = sr(n)
    cut = re.search(r"cutoff: ([^,)]+)", args)
    if cut:
        args = args.replace(cut.group(0), "cutoff: %s(%s)" % (s.name, lit(s, cut.group(1))))
    return fn, args, op(n).startswith("DirectedAcyclicGraph")


def sources_of(n):
    m = re.search(r"from: (\[[^\]]*\]|\d+)", op(n))
    x = eval(m.group(1))
    return x if isinstance(x, list) else [x]


# ---------------------------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------------------------

def path_check(n, var, receiver, path, endpoints, distance, ind, idx, extra=()):
    """The path's edges are consecutive arcs of `receiver`, and their ⊗-product is `distance`."""
    s = sr(n)
    e = "e.position" if idx == "$0.position" else "e"
    lines = [ind + "var product = %s.one" % s.name,
             ind + "for (k, e) in %s.edges.enumerated() {" % path,
             ind + "    #expect(%s.source(ofEdgeAt: e) == %s.vertices[k] && %s.target(ofEdgeAt: e) == %s.vertices[k + 1])" % (receiver, path, receiver, path),
             ind + "    product = product.times(%s(w[%s]))" % (type_base(s), e),
             ind + "}",
             ind + "#expect(%s)" % endpoints,
             ind + "#expect(product == %s)" % distance]
    return lines + [ind + x for x in extra]


def tree_checks(n, tree, receiver, g, ind, idx, values):
    s = sr(n)
    sc = scalar(s)
    vs = split_list(values)
    assert len(vs) == g.n
    lits = [lit(s, v) for v in vs]
    lines = [ind + "let expected: [%s?] = %s" % (sc, wrap(lits, ind)),
             ind + "#expect((0 ..< %d).map { %s.distance(to: $0)?.value } == expected)" % (g.n, tree),
             ind + "#expect((0 ..< %d).map { %s.distance(toIndex: $0)?.value } == expected)" % (g.n, tree),
             ind + "#expect((0 ..< %d).map { %s.hasPath(to: $0) } == expected.map { $0 != nil })" % (g.n, tree),
             ind + "#expect(%s.sources == %s)" % (tree, list(dict.fromkeys(sources_of(n))))]
    lines += [ind + "// Every tree path: arcs of the graph from a source, whose ⊗-product is the distance.",
              ind + "for v in 0 ..< %d {" % g.n,
              ind + "    guard let path = %s.path(to: v) else { continue }" % tree]
    lines += path_check(n, "v", receiver, "path", "path.vertices.last == v && %s.sources.contains(path.vertices[0])" % tree,
                        "%s.distance(to: v)" % tree, ind + "    ", idx,
                        ["#expect(%s.parentEdge(of: v) == path.edges.last)" % tree])
    lines.append(ind + "}")
    return lines


def matrix_checks(n, mat, receiver, g, ind, idx, values):
    s = sr(n)
    sc = scalar(s)
    rows = split_matrix(values)
    assert len(rows) == g.n and all(len(r) == g.n for r in rows)
    body = [wrap([lit(s, v) for v in r], ind + "    ") for r in rows]
    lines = [ind + "let expected: [[%s?]] = [" % sc]
    lines += [ind + "    " + b + "," for b in body]
    lines += [ind + "]",
              ind + "#expect((0 ..< %d).map { i in (0 ..< %d).map { %s.distance(from: i, to: $0)?.value } } == expected)" % (g.n, g.n, mat),
              ind + "#expect((0 ..< %d).map { i in (0 ..< %d).map { %s.distance(fromIndex: i, toIndex: $0)?.value } } == expected)" % (g.n, g.n, mat),
              ind + "#expect((0 ..< %d).map { i in (0 ..< %d).map { %s.hasPath(from: i, to: $0) } } == expected.map { $0.map { $0 != nil } })" % (g.n, g.n, mat),
              ind + "// Every path: arcs of the graph from i to j, whose ⊗-product is the distance; nil where no path.",
              ind + "for i in 0 ..< %d {" % g.n,
              ind + "    for j in 0 ..< %d {" % g.n,
              ind + "        let path = %s.path(from: i, to: j)" % mat,
              ind + "        #expect((path == nil) == (expected[i][j] == nil))",
              ind + "        guard let path else { continue }"]
    lines += path_check(n, "j", receiver, "path", "path.vertices.first == i && path.vertices.last == j",
                        "%s.distance(from: i, to: j)" % mat, ind + "        ", idx)
    lines += [ind + "    }", ind + "}"]
    return lines


# ---------------------------------------------------------------------------------------------
# Row tests
# ---------------------------------------------------------------------------------------------

def header(n, throws=False, is_async=False):
    title = "SR-%03d %s (%s" % (n, case(n), sname(n))
    title += ")" if inp(n) == "—" or not inp(n).startswith("a =") else ": %s)" % inp(n)
    eff = (" async" if is_async else "") + (" throws" if throws else "")
    return ['    @Test("%s")' % title.replace('"', '\\"'), "    func sr%03d()%s {" % (n, eff)]


def comment(n):
    return "        // %s → %s" % (op(n), cell(n) if len(cell(n)) < 200 else cell(n)[:200] + " …")


def operand_lines(n, ind, used):
    s = sr(n)
    lines = []
    for part in inp(n).split(", "):
        k, v = part.split(" = ")
        if k in used:
            lines.append(ind + "let %s = %s(%s)" % (k, s.name, lit(s, v)))
    return lines


def methods(expr, sname):
    """`(a ⊕ b) ⊗ .one` → `a.plus(b).times(S.one)`: the requirements' spelling of an operator law."""
    toks = re.findall(r"\.zero|\.one|[abc]|[()⊕⊗]", expr)
    assert "".join(toks) == expr.replace(" ", ""), expr
    pos = [0]

    def peek():
        return toks[pos[0]] if pos[0] < len(toks) else None

    def take():
        pos[0] += 1
        return toks[pos[0] - 1]

    def atom():
        t = take()
        if t == "(":
            x = plus()
            assert take() == ")"
            return x
        return sname + t if t.startswith(".") else t

    def times():
        x = atom()
        while peek() == "⊗":
            take()
            x = "%s.times(%s)" % (x, atom())
        return x

    def plus():
        x = times()
        while peek() == "⊕":
            take()
            x = "%s.plus(%s)" % (x, times())
        return x
    out = plus()
    assert pos[0] == len(toks), expr
    return out


def law_test(n):
    """The law written with the requirements, plus(_:) and times(_:); then the operators, which must agree."""
    s = sr(n)
    text = op(n)
    used = [x for x in "abc" if re.search(r"\b%s\b" % x, text)]
    lines = header(n) + [comment(n)] + operand_lines(n, "        ", used)
    c = cell(n)
    if text in ("a < b",):
        lines.append("        #expect(%s(a < b))" % ("" if c == "true" else "!"))
        lines.append("        // The natural order: a < b exactly when a.plus(b) == a and a != b.")
        lines.append("        #expect((a < b) == (a.plus(b) == a && a != b))")
        lines.append("        #expect(%s(b < a) && a != b)" % ("!" if c == "true" else ""))
    elif text == "a < .zero || a == .zero":
        assert c == "true"
        lines.append("        #expect(a < .zero || a == .zero)")
        lines.append("        #expect(!(%s.zero < a))" % s.name)
        lines.append("        #expect(a.plus(.zero) == a)")
    elif text == "a ⊕ a == a":
        m = re.fullmatch(r"(true|false) \(a ⊕ a = (.+)\)", c)
        lines.append("        let sum = a.plus(a)")
        lines.append("        #expect(%s)" % ("sum == a" if m.group(1) == "true" else "sum != a"))
        lines.append("        #expect(sum.value == %s)" % lit(s, m.group(2)))
        lines.append("        #expect((a ⊕ a) == sum)")
    elif text == "a ⊕ b == (b < a ? b : a)":
        m = re.fullmatch(r"true \((.+)\)", c)
        lines.append("        let sum = a.plus(b)")
        lines.append("        #expect(sum == (b < a ? b : a))")
        lines.append("        #expect(sum == a || sum == b)")
        lines.append("        #expect(sum.value == %s)" % lit(s, m.group(1)))
        lines.append("        #expect((a ⊕ b) == sum)")
    else:
        m = re.fullmatch(r"both (.+)", c)
        lhs, rhs = text.split(" == ")
        lines.append("        let lhs: %s = %s" % (s.name, methods(lhs, s.name)))
        lines.append("        let rhs: %s = %s" % (s.name, methods(rhs, s.name)))
        lines.append("        #expect(lhs == rhs)")
        lines.append("        #expect(lhs.value == %s && rhs.value == %s)" % (lit(s, m.group(1)), lit(s, m.group(1))))
        lines.append("        // The operators call the methods.")
        lines.append("        let lhsOperators: %s = %s" % (s.name, lhs))
        lines.append("        let rhsOperators: %s = %s" % (s.name, rhs))
        lines.append("        #expect(lhsOperators == lhs && rhsOperators == rhs)")
    return lines + ["    }"]


def constants_test(n):
    s = sr(n)
    lines = header(n) + [comment(n)]
    lines.append("        #expect(%s.zero.value == %s && %s.one.value == %s)" % (s.name, vlit(s, s.zero), s.name, vlit(s, s.one)))
    lines.append("        #expect(%s.zero == %s(%s) && %s.one == %s(%s))" % (s.name, s.name, vlit(s, s.zero), s.name, s.name, vlit(s, s.one)))
    lines.append("        // CustomStringConvertible: the value.")
    lines.append('        #expect(%s.zero.description == "%s" && %s.one.description == "%s")'
                 % (s.name, swift_description(s, s.zero), s.name, swift_description(s, s.one)))
    lines.append('        #expect("\\(%s(%s))" == "%s")' % (s.name, vlit(s, s.one), swift_description(s, s.one)))
    if s.selective:
        lines.append("        // zero is the worst element, one beats it.")
        lines.append("        #expect(%s.one < %s.zero)" % (s.name, s.name))
    lines.append("        // Hashable: equal values hash alike.")
    lines.append("        #expect(Set([%s.zero, %s(%s), %s.one]).count == 2)" % (s.name, s.name, vlit(s, s.zero), s.name))
    return lines + ["    }"]


def arithmetic_test(n):
    s = sr(n)
    text = op(n)
    lines = header(n) + [comment(n)] + operand_lines(n, "        ", ["a", "b"])
    method = "times" if "⊗" in text else "plus"
    lines.append("        #expect((%s).value == %s)" % (text, lit(s, cell(n))))
    lines.append("        #expect(a.%s(b).value == %s && b.%s(a).value == %s)" % (method, lit(s, cell(n)), method, lit(s, cell(n))))
    return lines + ["    }"]


def not_available_test(n):
    s = sr(n)
    g = graph_of(n)
    assert g.directed and len(g.edges) == 1
    lines = header(n, throws=True) + [comment(n)]
    lines += ["        // The call does not type-check: dijkstraShortestPaths takes S: SelectiveSemiring.",
              "        #if false",
              "        let rejected = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])",
              "        _ = rejected.dijkstraShortestPaths(from: 0) { _ in %s(1) }" % s.name,
              "        #endif",
              "        func isSemiring(_ type: Any.Type) -> Bool { type is any Semiring.Type }",
              "        func isSelective(_ type: Any.Type) -> Bool { type is any SelectiveSemiring.Type }",
              "        func isComparable(_ type: Any.Type) -> Bool { type is any Comparable.Type }",
              "        #expect(isSemiring(%s.self))" % s.name,
              "        #expect(!isSelective(%s.self) && !isComparable(%s.self))" % (s.name, s.name),
              "        // dagShortestDistances is the entry point that takes it.",
              "        let graph = DirectedPseudograph(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])",
              "        let distances = try #require(graph.dagShortestDistances(from: 0) { _ in %s(1) })" % s.name,
              "        #expect([distances.distance(to: 0).value, distances.distance(to: 1).value] == [1, 1])"]
    return lines + ["    }"]


def algorithm_body(n, ind):
    """Lines that build the graph, run the row's call and check its result."""
    s = sr(n)
    g = graph_of(n)
    fn, args, wrapped = call_parts(n)
    lines, view, idx = graph_lines(n, ind)
    receiver = view
    if wrapped:
        lines.append(ind + "let dag = try #require(DirectedAcyclicGraph(graph))")
        receiver = "dag"
    clo = weight_closure(n, idx)
    call = "%s.%s(%s) %s" % (receiver, fn, args, clo)
    c = cell(n)
    if fn in ("dijkstraShortestPaths",):
        lines.append(ind + "let tree = %s" % call)
        lines += tree_checks(n, "tree", receiver, g, ind, idx, c)
    elif fn in ("bellmanFordShortestPaths", "dagShortestPaths"):
        if c == "nil":
            lines.append(ind + "#expect(%s == nil)" % call)
        else:
            lines.append(ind + "let tree = %s" % (call if wrapped else "try #require(%s)" % call))
            lines += tree_checks(n, "tree", receiver, g, ind, idx, c)
    elif fn == "dijkstraShortestPath":
        target = int(re.search(r"to: (\d+)", args).group(1))
        if c == "nil":
            lines.append(ind + "#expect(%s == nil)" % call)
            lines.append(ind + "#expect(%s.dijkstraShortestPaths(from: %d) %s.distance(to: %d) == nil)" % (receiver, sources_of(n)[0], clo, target))
        else:
            m = re.fullmatch(r"vertices (\[.*?\]), edges (\[.*?\]), distance (.+)", c)
            assert m, c
            lines.append(ind + "let result = try #require(%s)" % call)
            lines.append(ind + "#expect(result.path.vertices == %s && result.path.edges == %s)" % (m.group(1), m.group(2)))
            lines.append(ind + "#expect(result.distance.value == %s)" % lit(s, m.group(3)))
            lines.append(ind + "// The same distance as the tree's.")
            lines.append(ind + "#expect(%s.dijkstraShortestPaths(from: %d) %s.distance(to: %d) == result.distance)" % (receiver, sources_of(n)[0], clo, target))
            lines += path_check(n, "", receiver, "result.path", "result.path.vertices.first == %d && result.path.vertices.last == %d" % (sources_of(n)[0], target),
                                "result.distance", ind, idx)
    elif fn == "dagShortestDistances":
        if c == "nil":
            lines.append(ind + "#expect(%s == nil)" % call)
        else:
            vs = split_list(c)
            assert len(vs) == g.n
            lines.append(ind + "let distances = %s" % (call if wrapped else "try #require(%s)" % call))
            lines.append(ind + "let expected: [%s] = %s" % (scalar(s), wrap([lit(s, v) for v in vs], ind)))
            lines.append(ind + "#expect((0 ..< %d).map { distances.distance(to: $0).value } == expected)" % g.n)
            lines.append(ind + "#expect((0 ..< %d).map { distances.distance(toIndex: $0).value } == expected)" % g.n)
            lines.append(ind + "#expect(distances.sources == %s)" % list(dict.fromkeys(sources_of(n))))
            if s.selective:
                lines.append(ind + "// The same as dagShortestPaths, with zero where it reaches nothing.")
                lines.append(ind + "let tree = try #require(%s.dagShortestPaths(%s) %s)" % (receiver, args, clo))
                lines.append(ind + "#expect((0 ..< %d).map { tree.distance(to: $0) ?? .zero } == (0 ..< %d).map { distances.distance(to: $0) })" % (g.n, g.n))
    elif fn == "floydWarshallShortestPaths":
        call = "%s.floydWarshallShortestPaths %s" % (receiver, clo)
        if c == "nil":
            lines.append(ind + "#expect(%s == nil)" % call)
        else:
            lines.append(ind + "let matrix = try #require(%s)" % call)
            lines += matrix_checks(n, "matrix", receiver, g, ind, idx, c)
    else:
        raise ValueError(op(n))
    return lines, receiver, idx


def agreement_lines(n, receiver, idx, ind):
    """The extra reference of an agreement row: the W overload, or Traversal's descendants."""
    fn, args, _ = call_parts(n)
    g = graph_of(n)
    c = cell(n)
    if case(n).startswith("the W overload"):
        wclo = "{ w[%s] }" % idx
        if fn == "floydWarshallShortestPaths":
            return [ind + "// The W overload: the same matrix.",
                    ind + "let reference = try #require(%s.floydWarshallShortestPaths %s)" % (receiver, wclo),
                    ind + "#expect((0 ..< %d).map { i in (0 ..< %d).map { reference.distance(from: i, to: $0) } } == expected)" % (g.n, g.n)]
        if c == "nil":
            return [ind + "// The W overload: nil too.",
                    ind + "#expect(%s.%s(%s) %s == nil)" % (receiver, fn, args, wclo)]
        call = "%s.%s(%s) %s" % (receiver, fn, args, wclo)
        if fn == "bellmanFordShortestPaths":
            call = "try #require(%s)" % call
        return [ind + "// The W overload: the same distances.",
                ind + "let reference = %s" % call,
                ind + "#expect((0 ..< %d).map { reference.distance(to: $0) } == expected)" % g.n]
    if "descendants" in case(n):
        return [ind + "// Traversal's descendants(of:), with the source.",
                ind + "#expect(Set((0 ..< %d).filter { tree.hasPath(to: $0) }) == graph.descendants(of: 0).union([0]))" % g.n]
    return []


def algorithm_test(n):
    lines, receiver, idx = algorithm_body(n, "        ")
    if group(n) == "Agreement":
        lines += agreement_lines(n, receiver, idx, "        ")
    throws = any("try " in l for l in lines)
    return header(n, throws=throws) + [comment(n)] + lines + ["    }"]


# ---------------------------------------------------------------------------------------------
# Trap rows: the call in a child process, then the setup without the fault
# ---------------------------------------------------------------------------------------------
# Keyed by (semiring, operands): the setup without the fault, run in this process.
WITHOUT = {
    ("TropicalSemiring<Int>", "a = Int.max - 3, b = 4"): ["// One less: the largest finite sum, and a sum landing on Int.max is zero.",
          "#expect((TropicalSemiring<Int>(Int.max - 3) ⊗ TropicalSemiring<Int>(2)).value == Int.max - 1)",
          "#expect((TropicalSemiring<Int>(Int.max - 3) ⊗ TropicalSemiring<Int>(3)) == .zero)"],
    ("TropicalSemiring<Int>", "a = Int.min + 3, b = -4"): ["// One less: the most negative sum that fits.",
          "#expect((TropicalSemiring<Int>(Int.min + 3) ⊗ TropicalSemiring<Int>(-3)).value == Int.min)"],
    ("CountingSemiring<Int>", "a = Int.max, b = 1"): ["// The largest sums that fit.",
          "#expect((CountingSemiring<Int>(Int.max) ⊕ CountingSemiring<Int>(0)).value == Int.max)",
          "#expect((CountingSemiring<Int>(Int.max - 1) ⊕ CountingSemiring<Int>(1)).value == Int.max)"],
    ("CountingSemiring<Int>", "a = 4294967296, b = 2147483648"): ["// One less: the largest product that fits.",
          "#expect((CountingSemiring<Int>(4294967296) ⊗ CountingSemiring<Int>(2147483647)).value == 9223372032559808512)"],
    ("TropicalSemiring<Int8>", "a = Int8.max - 7, b = 8"): ["// One less lands on Int8.max: zero.",
          "#expect((TropicalSemiring<Int8>(Int8.max - 7) ⊗ TropicalSemiring<Int8>(7)) == .zero)"],
    ("TropicalSemiring<Int16>", "a = Int16.min + 1, b = -2"): ["// One less lands on Int16.min: −∞, which absorbs.",
          "#expect((TropicalSemiring<Int16>(Int16.min + 1) ⊗ TropicalSemiring<Int16>(-1)).value == Int16.min)"],
    ("TropicalSemiring<Int32>", "a = Int32.max - 1, b = 2"): ["// One less lands on Int32.max: zero.",
          "#expect((TropicalSemiring<Int32>(Int32.max - 1) ⊗ TropicalSemiring<Int32>(1)) == .zero)"],
    ("TropicalSemiring<UInt8>", "a = 200, b = 56"): ["// One less lands on UInt8.max: zero.",
          "#expect((TropicalSemiring<UInt8>(200) ⊗ TropicalSemiring<UInt8>(55)) == .zero)"],
    ("TropicalSemiring<UInt64>", "a = UInt64.max - 2, b = 3"): ["// One less lands on UInt64.max: zero.",
          "#expect((TropicalSemiring<UInt64>(UInt64.max - 2) ⊗ TropicalSemiring<UInt64>(2)) == .zero)"],
}


def trap_test(n):
    s = sr(n)
    lines = header(n, is_async=True) + [comment(n)]
    if group(n) == "Arithmetic":
        lines.append("        await #expect(processExitsWith: .failure) {")
        lines += operand_lines(n, "            ", ["a", "b"])
        lines.append("            _ = %s" % op(n))
        lines.append("        }")
        lines.append("        // The method the operator calls traps too.")
        lines.append("        await #expect(processExitsWith: .failure) {")
        lines += operand_lines(n, "            ", ["a", "b"])
        lines.append("            _ = a.%s(b)" % ("times" if "⊗" in op(n) else "plus"))
        lines.append("        }")
        lines += ["        " + l for l in WITHOUT[(sname(n), inp(n))]]
        return lines + ["    }"]
    fn, args, wrapped = call_parts(n)
    glines, view, idx = graph_lines(n, "            ")
    clo = weight_closure(n, idx)
    lines.append("        await #expect(processExitsWith: .failure) {")
    lines += glines
    lines.append("            _ = %s.%s(%s) %s" % (view, fn, args, clo))
    lines.append("        }")
    glines, view, idx = graph_lines(n, "        ")
    g = graph_of(n)
    if fn == "dijkstraShortestPaths" and "better than one" in cell(n):
        # Without the call that examines a negative weight: from 3 nothing is examined, and
        # Bellman–Ford takes the same graph.
        d = ref.dijkstra(g, s, [3])[0]
        bf = ref.bellman_ford(g, s, [0])
        lines.append("        // Without the fault: from 3 no weight is examined, and Bellman–Ford takes the graph.")
        lines += glines
        lines.append("        let tree = %s.dijkstraShortestPaths(from: 3) %s" % (view, clo))
        lines.append("        #expect((0 ..< %d).map { tree.distance(to: $0)?.value } == %s)" % (g.n, "[" + ", ".join(vlit(s, x) for x in d) + "]"))
        lines.append("        let reference = try #require(%s.bellmanFordShortestPaths(from: 0) %s)" % (view, clo))
        lines.append("        #expect((0 ..< %d).map { reference.distance(to: $0)?.value } == %s)" % (g.n, "[" + ", ".join(vlit(s, x) for x in bf) + "]"))
        return [l.replace("async {", "async throws {") for l in lines] + ["    }"]
    if fn == "dijkstraShortestPaths":
        # The overflowing sum is 0 → 1 → 2; from 1 it is one weight.
        d = ref.dijkstra(g, s, [1])[0]
        lines.append("        // Without the fault: from 1, one weight, no sum.")
        lines += glines
        lines.append("        let tree = %s.dijkstraShortestPaths(from: 1) %s" % (view, clo))
        lines.append("        #expect((0 ..< %d).map { tree.distance(to: $0)?.value } == %s)" % (g.n, "[" + ", ".join(vlit(s, x) for x in d) + "]"))
        return lines + ["    }"]
    if fn == "dagShortestDistances":
        kind, a = token(n)
        start = 2 if kind == "ladder" else a[1] + 1
        d = ref.dag_distances(g, s, [start])
        lines.append("        // Without the fault: from vertex %d the counts fit; the last is %s." % (start, d[-1]))
        lines += glines
        lines.append("        let distances = try #require(graph.dagShortestDistances(from: %d) %s)" % (start, clo))
        lines.append("        #expect(distances.distance(to: %d).value == %s)" % (g.n - 1, d[-1]))
        lines.append("        #expect(distances.distance(to: 0).value == 0 && distances.distance(to: %d).value == 1)" % start)
        return [l.replace("async {", "async throws {") for l in lines] + ["    }"]
    raise ValueError(n)


# ---------------------------------------------------------------------------------------------
# "Phase 2" rows (--phase2)
# ---------------------------------------------------------------------------------------------

def phase2_test(n):
    s = sr(n)
    c = cell(n)
    lines = header(n, throws=False) + [comment(n)]
    if group(n) == "Phase 2: star":
        lines += operand_lines(n, "        ", ["a"])
        lines.append("        #expect(a.star.value == %s)" % lit(s, c))
        return lines + ["    }"]
    if group(n) == "Phase 2: laws":
        text = op(n)
        used = [x for x in "abc" if re.search(r"\b%s\b" % x, text)]
        lines += operand_lines(n, "        ", used)
        lhs, rhs = text.split(" == ")
        lines.append("        let lhs: %s = %s" % (s.name, lhs))
        lines.append("        let rhs: %s = %s" % (s.name, rhs))
        v = c[len("both "):]
        if v.startswith("≈"):
            x = v[1:]
            lines.append("        #expect(abs(lhs.value - rhs.value) <= 1e-12 * max(1, abs(lhs.value)))")
            lines.append("        #expect(abs(lhs.value - %s) <= 1e-11 * max(1, abs(%s)))" % (x, x))
        else:
            lines.append("        #expect(lhs == rhs && lhs.value == %s)" % lit(s, v))
        return lines + ["    }"]
    glines, view, idx = graph_lines(n, "        ")
    g = graph_of(n)
    clo = weight_closure(n, idx)
    lines += glines
    if group(n) == "Phase 2: Kleene closure":
        rows = split_matrix(c)
        lines.append("        let closure = %s.kleeneClosure %s" % (view, clo))
        lines.append("        let expected: [[%s?]] = [" % scalar(s))
        lines += ["            " + wrap([lit(s, v) for v in r], "            ") + "," for r in rows]
        lines.append("        ]")
        lines.append("        #expect((0 ..< %d).map { i in (0 ..< %d).map { closure.distance(from: i, to: $0)?.value } } == expected)" % (g.n, g.n))
        return lines + ["    }"]
    # Phase 2: Log, dagShortestDistances.
    vs = [v[1:] for v in split_list(c)]
    out = header(n, throws=True) + [comment(n)] + glines
    out.append("        let distances = try #require(%s.dagShortestDistances(from: 0) %s)" % (view, clo))
    out.append("        let expected: [Double] = [%s]" % ", ".join(vs))
    out.append("        for v in 0 ..< %d {" % g.n)
    out.append("            #expect(abs(distances.distance(to: v).value - expected[v]) <= 1e-11)")
    out.append("        }")
    return out + ["    }"]


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

FLOAT16_GUARD = "#if !((os(macOS) || targetEnvironment(macCatalyst)) && arch(x86_64))"


def test_for(n):
    lines = test_body(n)
    if "Float16" in sname(n):
        # Float16 is unavailable on Intel Macs.
        return ["    " + FLOAT16_GUARD] + lines + ["    #endif"]
    return lines


def test_body(n):
    if is_trap(n):
        return trap_test(n)
    g = group(n)
    if g == "Constants":
        return constants_test(n)
    if g in ("Laws", "Order"):
        return law_test(n)
    if g == "Arithmetic":
        return arithmetic_test(n)
    if g == "Not available":
        return not_available_test(n)
    return algorithm_test(n)


def ids(*groups, ops=None):
    out = []
    for n in range(1, P2):
        if is_trap(n) or group(n) not in groups:
            continue
        if ops and not any(op(n).split("(")[0].endswith(o) or ("." + o + "(") in op(n) for o in ops):
            continue
        out.append(n)
    return out


TRAPS = [n for n in range(1, P2) if is_trap(n)]
ALGO = ("Dijkstra", "Bellman–Ford", "DAG", "DAG distances", "Floyd–Warshall")
FILES = [
    ("SemiringTypeTests.swift", "Semirings: zero, one and the types", ids("Constants", "Not available"),
     "The four semirings' constants (catalog SR-001 – SR-007, and the other scalar families from\n"
     f"// SR-{min(ids('Constants')[7:]):03d}): zero and one by value, their descriptions, zero worse than one by the\n"
     "// natural order, and hashing; and the counting semiring, which is not selective, so only\n"
     "// dagShortestDistances takes it (SR-%03d, SR-%03d)." % tuple(ids("Not available"))),
    ("SemiringLawTests.swift", "Semirings: laws and the natural order", ids("Laws", "Order"),
     "The semiring laws on the catalog's operands (SR-008 – SR-207, and from "
     f"SR-{min(n for n in ids('Laws') if n > 207):03d} one triple per\n"
     "// other scalar: fixed-width integers, Float, Float16): ⊕ associative and commutative, zero its\n"
     "// identity, ⊗ associative with identity one, zero annihilating, ⊗ distributing from both sides,\n"
     "// ⊗ commutative (true of all four, not required); selectivity and idempotence; and the natural\n"
     "// order, a < b when a ⊕ b == a != b, with zero the worst element."),
    ("SemiringArithmeticTests.swift", "Semirings: arithmetic at the edges", ids("Arithmetic"),
     "Arithmetic at the edges of the scalars (SR-208 – SR-217, and the other widths from "
     f"SR-{min(n for n in ids('Arithmetic') if n > 217):03d};\n"
     "// the trap rows are in SemiringPreconditionTests.swift): Int.max is the tropical zero and\n"
     "// absorbs, infinity absorbs, min of extremes never overflows, Double counts\n"
     "// round, and unsigned 0 is the bottleneck zero."),
    ("SemiringDijkstraTests.swift", "Semirings: Dijkstra over a selective semiring", ids("Dijkstra"),
     "Dijkstra over a selective semiring (catalog Dijkstra rows): shortest paths (tropical), widest\n"
     "// paths (bottleneck, with a cutoff meaning at least this wide) and reachability (Boolean); an\n"
     "// edge of weight zero carries no path; undirected graphs through .directedView."),
    ("SemiringBellmanFordTests.swift", "Semirings: Bellman–Ford over a selective semiring", ids("Bellman–Ford"),
     "Bellman–Ford over a selective semiring (catalog Bellman–Ford rows): nil when a cycle better\n"
     "// than one is reachable, which only the tropical semiring has."),
    ("SemiringDAGTests.swift", "Semirings: DAG paths and Mohri's shortest distances", ids("DAG", "DAG distances"),
     "DAG paths over a selective semiring and dagShortestDistances over any semiring (catalog DAG and\n"
     "// DAG distances rows): nil when a cycle is reachable, the maintained order of\n"
     "// DirectedAcyclicGraph, path counting with CountingSemiring (2^k, lattice paths, up to C(66, 33)),\n"
     "// weighted path sums, and several sources adding."),
    ("SemiringFloydWarshallTests.swift", "Semirings: Floyd–Warshall over a selective semiring", ids("Floyd–Warshall"),
     "Floyd–Warshall over a selective semiring (catalog Floyd–Warshall rows): all-pairs shortest and\n"
     "// widest paths, Warshall's reflexive transitive closure, nil when a diagonal entry ends better\n"
     "// than one (a negative cycle or loop)."),
    ("SemiringAgreementTests.swift", "Semirings: agreement with the W overloads and the references", ids("Agreement", "Overflow"),
     "Agreement rows: the semiring and W overloads give the same distances on the catalog's LCG\n"
     "// graphs; Boolean reachability is Traversal's descendants(of:); the bottleneck, Boolean and\n"
     "// counting rows were checked by ref.py against brute force and NetworkX. And SR-%03d: an Int.max\n"
     "// weight is the tropical zero, so it neither traps nor reaches." % ids("Overflow")[0]),
    ("SemiringPreconditionTests.swift", "Semirings: preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the fault, so the trap is the call's and not\n"
     "// the setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]


def write(fname, suite, rows, comment_text, extra=None, tags=""):
    tests = [test_for(n) if n < P2 else phase2_test(n) for n in rows]
    if extra:
        tests.append(extra)
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["Semirings", "Testing"]
    if "Pseudograph(" in text:
        imports += ["GraphProtocols", "Multigraphs", "ShortestPaths"]
    if "DirectedAcyclicGraph(" in text:
        imports.append("DirectedAcyclicGraphModule")
    if "descendants(" in text:
        imports.append("Traversal")
    if tags:
        imports.append("GrafluentTestSupport")
    imports = sorted(set(imports), key=str.lower)
    out = ["// " + comment_text, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rows, comment_text in FILES:
    extra = None
    tags = ""
    if fname == "SemiringPreconditionTests.swift":
        extra = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n")
        tags = ", .tags(.precondition)"
    k = write(fname, suite, rows, comment_text, extra, tags)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == P2 - 1, rows_total
assert sorted(n for _, _, rows, _ in FILES for n in rows) == list(range(1, P2))
phase2 = os.path.join(OUT, "SemiringPhase2Tests.swift")
if PHASE2:
    k = write("SemiringPhase2Tests.swift", "Semirings: phase 2 (star, kleeneClosure, LogSemiring)", list(range(P2, N + 1)),
              "Phase 2 (catalog SR-%03d – SR-%03d): star on the closed semirings, Lehmann's kleeneClosure (−∞\n"
              "// through a negative cycle) and LogSemiring. Written only with swiftgen.py --phase2." % (P2, N))
    print("SemiringPhase2Tests.swift", k)
elif os.path.exists(phase2):
    os.remove(phase2)
print("phase-1 catalog rows", rows_total, "tests", total)
