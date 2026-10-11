"""Writes the catalog-row test files of Tests/IsomorphismTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1 \
        python3 Tests/Catalogs/Isomorphism/swiftgen.py [--phase2] [OUT_DIR]
    # default OUT_DIR: Tests/IsomorphismTests

First checks that ref.py's model reproduces cases.md byte for byte (which re-runs every row against
brute force and the three libraries), then writes one @Test per phase-1 row (IS-001 – IS-181).
`--phase2` also writes AutomorphismGroupTests.swift for IS-182 – IS-233, for when
`automorphismGroup()` exists; without the flag that file is not written (and a stale one is left
alone).

Every matching row builds its graphs as `Pseudograph<Int>` or `DirectedPseudograph<Int>` with the
catalog's vertices and edges in position order, checks the catalog's value, then checks the rest
of the entry point's family on the same arguments: the whole lazy sequence (its length is ref.py's
count, no mapping twice, every mapping satisfies api.md's definition, written out in the test), the
yes/no answer, and the first mapping (valid, and the same on a second call). A unique mapping is
also read through every accessor. Weisfeiler–Leman rows compare hashes within the process and
pin partitions. Trap rows run the call in a child process (exit test), then the same setup without
it. Hand-written exit tests spliced into the precondition file: extra_traps.swift.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
PHASE2 = "--phase2" in sys.argv
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.join(HERE, "..", "..", "IsomorphismTests")

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
ref.define()
ref.number_rows()
ref.compute()
ref.HEADER = ref.HEADER.format(last=len(ref.ROWS), count=len(ref.ROWS))
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == ref.render(), "cases.md is not ref.py's output"
ROWS = {int(r[0][3:]): r for r in ref.ROWS}
N = len(ROWS)
assert N == 233
PHASE1 = range(1, 182)
assert all(not ROWS[n][1].startswith("Phase 2") for n in PHASE1)
assert all(ROWS[n][1].startswith("Phase 2") for n in range(182, N + 1))


def group(n): return ROWS[n][1]
def title(n): return ROWS[n][2]
def gcell(n): return ROWS[n][3]
def hcell(n): return ROWS[n][4]
def op(n): return ROWS[n][5]
def cell(n): return ROWS[n][6]
def is_trap(n): return cell(n).startswith("**trap**")


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def s(x): return '"%s"' % x if isinstance(x, str) else str(x)
def lit(xs): return "[" + ", ".join(s(x) for x in xs) + "]"


def vtype(g): return "String" if any(isinstance(v, str) for v in g.vertices) else "Int"


def graph_lines(var, g, ind):
    """`let var = Pseudograph<Int>(…)`, edges in position order."""
    t = vtype(g)
    kind = ("DirectedPseudograph<%s>" if g.directed else "Pseudograph<%s>") % t
    vs = g.vertices
    n = len(vs)
    vexpr = "Array(0 ..< %d)" % n if n and vs == list(range(n)) else lit(vs)
    pairs = [(vs[u], vs[v]) for u, v in g.edges]
    edge = (lambda a, b: "DirectedEdge(from: %s, to: %s)" % (s(a), s(b))) if g.directed else (lambda a, b: "UndirectedEdge(%s, %s)" % (s(a), s(b)))
    if not n:
        return [ind + "let %s = %s()" % (var, kind)]
    if not pairs:
        return [ind + "let %s = %s(vertices: %s)" % (var, kind, vexpr)]
    if len(pairs) <= 8:
        return [ind + "let %s = %s(vertices: %s, edges: [%s])" % (var, kind, vexpr, ", ".join(edge(a, b) for a, b in pairs))]
    chunks = [pairs[i:i + 12] for i in range(0, len(pairs), 12)]
    out = [ind + "let %sEdges: [[%s]] = [" % (var, t)]
    for i, c in enumerate(chunks):
        out.append(ind + "    " + ", ".join("[%s, %s]" % (s(a), s(b)) for a, b in c) + ("," if i < len(chunks) - 1 else ""))
    out.append(ind + "]")
    e = "DirectedEdge(from: $0[0], to: $0[1])" if g.directed else "UndirectedEdge($0[0], $0[1])"
    out.append(ind + "let %s = %s(vertices: %s, edges: %sEdges.map { %s })" % (var, kind, vexpr, var, e))
    return out


def color_lines(g, h, colors, ind, one_graph=False):
    """The colour tables: vertex colours by vertex, edge colours by position."""
    vcg, vch, ecg, ech = colors
    out = []
    if vcg is not None:
        out.append(ind + "let patternColor: [%s: String] = [%s]" % (vtype(g), ", ".join("%s: %s" % (s(v), s(str(c))) for v, c in zip(g.vertices, vcg))))
        if not one_graph:
            out.append(ind + "let targetColor: [%s: String] = [%s]" % (vtype(h), ", ".join("%s: %s" % (s(v), s(str(c))) for v, c in zip(h.vertices, vch))))
    if ecg is not None:
        out.append(ind + "let patternEdgeColor = %s" % lit([str(c) for c in ecg]))
        if not one_graph:
            out.append(ind + "let targetEdgeColor = %s" % lit([str(c) for c in ech]))
    return out


def color_args(colors, one_graph=False):
    vcg, _, ecg, _ = colors
    if one_graph:
        if ecg is not None:
            v = "{ patternColor[$0]! }" if vcg is not None else "{ _ in 0 }"
            return ", vertexColor: %s, edgeColor: { patternEdgeColor[$0] }" % v
        if vcg is not None:
            return ", vertexColor: { patternColor[$0]! }"
        return ""
    if ecg is not None:
        v = ("{ patternColor[$0]! }", "{ targetColor[$0]! }") if vcg is not None else ("{ _ in 0 }", "{ _ in 0 }")
        return ", vertexColor: %s, otherVertexColor: %s, edgeColor: { patternEdgeColor[$0] }, otherEdgeColor: { targetEdgeColor[$0] }" % v
    if vcg is not None:
        return ", vertexColor: { patternColor[$0]! }, otherVertexColor: { targetColor[$0]! }"
    return ""


FAMILY = {"iso": ("isIsomorphic", "isomorphism", "isomorphisms"),
          "induced": ("isSubgraphIsomorphic", "subgraphIsomorphism", "subgraphIsomorphisms"),
          "mono": ("isMonomorphic", "monomorphism", "monomorphisms")}
RULE = {"iso": "a bijection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included",
        "induced": "an injection, and m_G(u, v) = m_H(f(u), f(v)) for every ordered pair, u = v included",
        "mono": "an injection, and m_G(u, v) is contained in m_H(f(u), f(v)) as a multiset"}


def definition_lines(g, h, mode, colors, ind):
    """api.md's definition, written out: `isValid(images)` for images in pattern `vertices` order."""
    vcg, _, ecg, _ = colors
    t = vtype(g)
    ends = ("edge.source", "edge.target") if g.directed else ("edge.u", "edge.v")
    out = [ind + "// api.md's definition: m(u, v) is the %s between u and v (%s); a mapping is %s%s." % (
        "multiset of edge colours" if ecg is not None else "number of edges",
        "arcs from u to v" if g.directed else "both orders for an edge, once for a self-loop",
        RULE[mode], ", with equal vertex colours" if vcg is not None else "")]
    for var, table in (("pattern", "patternEdgeColor"), ("target", "targetEdgeColor")):
        if ecg is not None:
            out.append(ind + "var %sPairs: [[%s]: [String]] = [:]" % (var, t))
            out.append(ind + "for (position, edge) in %s.edges.enumerated() {" % var)
            out.append(ind + "    %sPairs[[%s, %s], default: []].append(%s[position])" % (var, ends[0], ends[1], table))
            if not g.directed:
                out.append(ind + "    if edge.u != edge.v { %sPairs[[edge.v, edge.u], default: []].append(%s[position]) }" % (var, table))
        else:
            out.append(ind + "var %sPairs: [[%s]: Int] = [:]" % (var, t))
            out.append(ind + "for edge in %s.edges {" % var)
            out.append(ind + "    %sPairs[[%s, %s], default: 0] += 1" % (var, ends[0], ends[1]))
            if not g.directed:
                out.append(ind + "    if edge.u != edge.v { %sPairs[[edge.v, edge.u], default: 0] += 1 }" % var)
        out.append(ind + "}")
    out.append(ind + "let isValid = { (images: [%s]) -> Bool in" % vtype(h))
    size = "images.count == target.vertexCount" if mode == "iso" else "images.count == pattern.vertexCount"
    if mode == "iso":
        size += " && images.count == pattern.vertexCount"
    out.append(ind + "    guard %s, Set(images).count == images.count, images.allSatisfy(target.contains) else { return false }" % size)
    out.append(ind + "    let image = Dictionary(uniqueKeysWithValues: zip(pattern.vertices, images))")
    if vcg is not None:
        out.append(ind + "    guard pattern.vertices.allSatisfy({ patternColor[$0] == targetColor[image[$0]!] }) else { return false }")
    out.append(ind + "    return pattern.vertices.allSatisfy { u in")
    out.append(ind + "        pattern.vertices.allSatisfy { v in")
    if ecg is not None:
        out.append(ind + "            let a = (patternPairs[[u, v]] ?? []).sorted(), b = (targetPairs[[image[u]!, image[v]!]] ?? []).sorted()")
        if mode == "mono":
            out.append(ind + "            return a.allSatisfy { c in a.filter { $0 == c }.count <= b.filter { $0 == c }.count }")
        else:
            out.append(ind + "            return a == b")
    else:
        out.append(ind + "            let a = patternPairs[[u, v]] ?? 0, b = targetPairs[[image[u]!, image[v]!]] ?? 0")
        out.append(ind + "            return a %s b" % ("<=" if mode == "mono" else "=="))
    out.append(ind + "        }")
    out.append(ind + "    }")
    out.append(ind + "}")
    return out


def header(n, tags=()):
    return ['    @Test("IS-%03d %s"%s)' % (n, title(n).replace('"', '\\"'), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def comment(n):
    h = " → `%s`" % hcell(n) if hcell(n) else ""
    return "        // `%s`%s; `%s` ⇒ %s" % (gcell(n), h, op(n), cell(n))


def fmt_set(maps, h):
    return "[" + ", ".join("[" + ", ".join(s(h.vertices[x]) for x in f) + "]" for f in sorted(maps)) + "]"


# ---------------------------------------------------------------------------------------------
# Matching rows
# ---------------------------------------------------------------------------------------------

def accessor_lines(g, h, f, var, ind):
    """Every accessor of a unique mapping f (index lists)."""
    images = [h.vertices[x] for x in f]
    pre = {x: g.vertices[u] for u, x in enumerate(f)}
    out = [ind + "#expect(Array(%s.images) == %s)" % (var, lit(images)),
           ind + "#expect(pattern.vertices.map { %s.image(of: $0) } == %s)" % (var, lit(images)),
           ind + "#expect(pattern.vertices.map { %s.image(safe: $0) } == %s)" % (var, lit(images)),
           ind + "#expect((0 ..< %d).map { target.vertex(atIndex: %s.imageIndex(ofIndex: $0)) } == (0 ..< %d).map { %s.image(of: pattern.vertex(atIndex: $0)) })" % (g.n, var, g.n, var),
           ind + "#expect(target.vertices.map { %s.preimage(of: $0) } == [%s])" % (var, ", ".join(s(pre[x]) if x in pre else "nil" for x in range(h.n)))]
    return out


def matching_test(n):
    g, h = ref.parse_graph(gcell(n)), ref.parse_graph(hcell(n))
    colors = ref.parse_colors(op(n))
    name = re.match(r"(\w+)", op(n)).group(1)
    mode = ref.MODES[name]
    maps = ref.match(g, h, mode, *colors)
    count = len(maps)
    assert h.n > 7 or sorted(maps) == sorted(ref.brute(g, h, mode, *colors))
    b, one, seq = FAMILY[mode]
    args = "to: target" + color_args(colors)
    ind = "        "
    throws = name == one and count == 1
    lines = header(n) + ["    func is%03d()%s {" % (n, " throws" if throws else ""), comment(n)]
    lines += graph_lines("pattern", g, ind) + graph_lines("target", h, ind) + color_lines(g, h, colors, ind)
    # The catalog's value.
    lines.append(ind + "// The catalog's value.")
    if name == b:
        assert cell(n) == ("true" if count else "false")
        lines.append(ind + "#expect(%spattern.%s(%s))" % ("" if count else "!", b, args))
    elif ".count" in op(n):
        assert cell(n) == "#%d" % count
        lines.append(ind + "let all = pattern.%s(%s).map { Array($0.images) }" % (seq, args))
        lines.append(ind + "#expect(all.count == %d)" % count)
    elif name == seq:
        expected = fmt_set(maps, h)
        assert cell(n) == "{" + expected[1:-1] + "}", (n, expected, cell(n))
        lines.append(ind + "let all = pattern.%s(%s).map { Array($0.images) }" % (seq, args))
        lines.append(ind + "#expect(Set(all) == %s)" % expected)
    else:
        assert name == one
        if count == 0:
            assert cell(n) == "nil"
            lines.append(ind + "#expect(pattern.%s(%s) == nil)" % (one, args))
        elif count == 1:
            assert cell(n) == ref.fmt_map(g, h, maps[0])
            lines.append(ind + "let mapping = try #require(pattern.%s(%s))" % (one, args))
            lines += accessor_lines(g, h, maps[0], "mapping", ind)
        else:
            assert cell(n) == "some (one of #%d)" % count
            lines.append(ind + "let mapping = pattern.%s(%s)" % (one, args))
            lines.append(ind + "#expect(mapping != nil)")
    # The rest of the family.
    lines.append(ind + "// The family on the same arguments: every mapping, the yes/no answer and the first mapping.")
    lines += definition_lines(g, h, mode, colors, ind)
    if not (".count" in op(n) or name == seq):
        lines.append(ind + "let all = pattern.%s(%s).map { Array($0.images) }" % (seq, args))
        lines.append(ind + "#expect(all.count == %d)" % count)
    elif name == seq:
        lines.append(ind + "#expect(all.count == %d)" % count)
    lines.append(ind + "#expect(Set(all).count == all.count)")
    lines.append(ind + "#expect(all.allSatisfy(isValid))")
    lines.append(ind + "#expect(Set(pattern.%s(%s)).count == %d)" % (seq, args, count))
    if name != b:
        lines.append(ind + "#expect(pattern.%s(%s) == %s)" % (b, args, "true" if count else "false"))
    lines.append(ind + "let first = pattern.%s(%s).map { Array($0.images) }" % (one, args))
    if count:
        lines.append(ind + "#expect(first.map(isValid) == true)")
        lines.append(ind + "// No randomness: a second call gives the same mapping.")
        lines.append(ind + "#expect(pattern.%s(%s).map { Array($0.images) } == first)" % (one, args))
    else:
        lines.append(ind + "#expect(first == nil)")
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Weisfeiler–Leman rows
# ---------------------------------------------------------------------------------------------

def iterations_of(n): return int(re.search(r"iterations: (-?\d+)", op(n)).group(1))


def graph_hash_test(n):
    g, h = ref.parse_graph(gcell(n)), ref.parse_graph(hcell(n))
    colors = ref.parse_colors(op(n))
    k = iterations_of(n)
    assert cell(n) in ("equal", "different")
    ind = "        "
    lines = header(n) + ["    func is%03d() {" % n, comment(n)]
    lines += graph_lines("pattern", g, ind) + graph_lines("target", h, ind) + color_lines(g, h, colors, ind)
    pa = color_args(colors, one_graph=True)
    ta = pa.replace("patternColor", "targetColor").replace("patternEdgeColor", "targetEdgeColor")
    lines.append(ind + "let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: %d%s)" % (k, pa))
    lines.append(ind + "let targetHash = target.weisfeilerLehmanGraphHash(iterations: %d%s)" % (k, ta))
    lines.append(ind + "#expect(patternHash %s targetHash)" % ("==" if cell(n) == "equal" else "!="))
    lines.append(ind + "// Equal inputs hash alike within the process.")
    lines.append(ind + "#expect(pattern.weisfeilerLehmanGraphHash(iterations: %d%s) == patternHash)" % (k, pa))
    if k == 3 and pa == "":
        lines.append(ind + "// iterations defaults to 3.")
        lines.append(ind + "#expect(pattern.weisfeilerLehmanGraphHash() == patternHash && target.weisfeilerLehmanGraphHash() == targetHash)")
    lines.append("    }")
    return lines


def partitions_of(n):
    """The model's partitions, checked against the cell."""
    g = ref.parse_graph(gcell(n))
    vcg, _, ecg, _ = ref.parse_colors(op(n))
    k = iterations_of(n)
    rounds = ref.wl_rounds(g, k, vcg, ecg)
    parts = [ref.partition(r, g.vertices) for r in rounds[1:]]
    text = "; ".join("r%d: %s" % (i + 1, ref.fmt_part(p)) for i, p in enumerate(parts)) if parts else "(no rounds)"
    assert text == cell(n), (n, text)
    return g, k, parts


def subgraph_hashes_test(n):
    g, k, parts = partitions_of(n)
    colors = ref.parse_colors(op(n))
    ind = "        "
    lines = header(n) + ["    func is%03d() {" % n, comment(n)]
    lines += graph_lines("graph", g, ind) + color_lines(g, None, colors, ind, one_graph=True)
    a = color_args(colors, one_graph=True)
    lines.append(ind + "let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: %d%s)" % (k, a))
    lines.append(ind + "#expect(hashes.iterations == %d)" % k)
    lines.append(ind + "#expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == %d })" % k)
    lines.append(ind + "#expect((0 ..< %d).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })" % g.n)
    if k:
        lines.append(ind + "// Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.")
        lines.append(ind + "let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }")
        lines.append(ind + "var partitions: [[[%s]]] = []" % vtype(g))
        lines.append(ind + "for round in 0 ..< %d {" % k)
        lines.append(ind + "    var classes: [Int: [%s]] = [:]" % vtype(g))
        lines.append(ind + "    var order: [Int] = []")
        lines.append(ind + "    for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {")
        lines.append(ind + "        if classes[hash] == nil { order.append(hash) }")
        lines.append(ind + "        classes[hash, default: []].append(vertex)")
        lines.append(ind + "    }")
        lines.append(ind + "    partitions.append(order.map { classes[$0]! })")
        lines.append(ind + "}")
        lines.append(ind + "#expect(partitions == [%s])" % ", ".join("[" + ", ".join(lit(c) for c in p) + "]" for p in parts))
        lines.append(ind + "// Equal inputs hash alike within the process.")
        lines.append(ind + "let again = graph.weisfeilerLehmanSubgraphHashes(iterations: %d%s)" % (k, a))
        lines.append(ind + "#expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })")
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Accessor rows
# ---------------------------------------------------------------------------------------------

def accessor_parse(n):
    mm = re.match(r"(image|preimage)\(of: (-?\w+)\) after (\w+)", op(n))
    return mm.group(1), ref.items(mm.group(2))[0], mm.group(3)


def accessor_setup(n, ind):
    g, h = ref.parse_graph(gcell(n)), ref.parse_graph(hcell(n))
    colors = ref.parse_colors(op(n))
    _, _, call = accessor_parse(n)
    maps = ref.match(g, h, ref.MODES[call], *colors)
    assert len(maps) == 1
    lines = graph_lines("pattern", g, ind) + graph_lines("target", h, ind) + color_lines(g, h, colors, ind)
    return g, h, maps[0], "pattern.%s(to: target%s)" % (call, color_args(colors)), lines


def accessor_test(n):
    which, v, call = accessor_parse(n)
    ind = "        "
    lines = header(n) + ["    func is%03d() throws {" % n, comment(n)]
    g, h, f, expr, setup = accessor_setup(n, ind)
    lines += setup
    lines.append(ind + "let mapping = try #require(%s)" % expr)
    lines.append(ind + "// The catalog's value.")
    if which == "image":
        r = h.vertices[f[g.vertices.index(v)]]
        assert cell(n) == str(r)
        lines.append(ind + "#expect(mapping.image(of: %s) == %s)" % (s(v), s(r)))
        lines.append(ind + "#expect(mapping.image(safe: %s) == %s)" % (s(v), s(r)))
    else:
        x = h.vertices.index(v)
        r = g.vertices[f.index(x)] if x in f else None
        assert cell(n) == ("nil" if r is None else str(r))
        lines.append(ind + "#expect(mapping.preimage(of: %s) == %s)" % (s(v), "nil" if r is None else s(r)))
    lines.append(ind + "// Every accessor.")
    lines += accessor_lines(g, h, f, "mapping", ind)
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Trap rows
# ---------------------------------------------------------------------------------------------

def trap_test(n):
    ind = "            "
    lines = header(n) + ["    func is%03d() async {" % n, comment(n)]
    name = re.match(r"(\w+)", op(n)).group(1)
    if name in ("weisfeilerLehmanGraphHash", "weisfeilerLehmanSubgraphHashes"):
        assert cell(n) == "**trap** (iterations must be at least 0)"
        g = ref.parse_graph(gcell(n))
        k = iterations_of(n)
        assert k < 0
        lines.append("        await #expect(processExitsWith: .failure) {")
        lines += graph_lines("graph", g, ind)
        lines.append(ind + "_ = graph.%s(iterations: %d)" % (name, k))
        lines.append("        }")
        lines.append("        // Without the call: iterations 0, the least, answers.")
        lines += graph_lines("graph", g, "        ")
        if name == "weisfeilerLehmanGraphHash":
            lines.append("        #expect(graph.weisfeilerLehmanGraphHash(iterations: 0) == graph.weisfeilerLehmanGraphHash(iterations: 0))")
        else:
            lines.append("        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 0)")
            lines.append("        #expect(hashes.iterations == 0 && graph.vertices.allSatisfy { hashes.hashes(of: $0).isEmpty })")
        lines.append("    }")
        return lines
    which, v, call = accessor_parse(n)
    g, h, f, expr, setup = accessor_setup(n, ind)
    if which == "image":
        assert v not in g.vertices and cell(n) == "**trap** (%s is not a vertex of the pattern)" % v
    else:
        assert v not in h.vertices and cell(n) == "**trap** (%s is not a vertex of the target)" % v
    lines.append("        await #expect(processExitsWith: .failure) {")
    lines += setup
    lines.append(ind + "let mapping = %s!" % expr)
    lines.append(ind + "_ = mapping.%s(of: %s)" % (which, s(v)))
    lines.append("        }")
    lines.append("        // Without the call: the mapping, and its accessors on vertices.")
    _, _, _, _, setup = accessor_setup(n, "        ")
    lines += setup
    lines.append("        guard let mapping = %s else {" % expr)
    lines.append("            Issue.record(\"no mapping\")")
    lines.append("            return")
    lines.append("        }")
    if which == "image":
        lines.append("        #expect(mapping.image(safe: %s) == nil)" % s(v))
    lines += accessor_lines(g, h, f, "mapping", "        ")
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Phase 2 (--phase2): automorphismGroup()
# ---------------------------------------------------------------------------------------------

def automorphism_test(n):
    g = ref.parse_graph(gcell(n))
    colors = ref.parse_colors(op(n))
    vcg, _, ecg, _ = colors
    order, orbits = ref.automorphisms_info(g, vcg, ecg)
    ind = "        "
    lines = header(n) + ["    func is%03d() {" % n, comment(n)]
    lines += graph_lines("graph", g, ind) + color_lines(g, None, colors, ind, one_graph=True)
    lines.append(ind + "let group = graph.automorphismGroup(%s)" % color_args(colors, one_graph=True)[2:])
    lines.append(ind + "// The catalog's value.")
    if "().order" in op(n):
        assert cell(n) == str(order)
        lines.append(ind + "#expect(group.order == %s)" % (("%d" % order) if order < 2 ** 53 else repr(float(order))))
    else:
        names = [[g.vertices[i] for i in o] for o in orbits]
        assert cell(n) == ("(none)" if not names else ref.fmt_part(names))
        lines.append(ind + "#expect(group.orbits.map { Array($0) } == [%s])" % ", ".join(lit(o) for o in names))
        lines.append(ind + "#expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })")
    lines.append(ind + "// The stabiliser chain's lengths multiply to the order.")
    if order < 2 ** 62:
        lines.append(ind + "#expect(group.basicOrbitLengths.reduce(1, *) == %d)" % order)
    else:
        lines.append(ind + "#expect(abs(group.basicOrbitLengths.reduce(1.0) { $0 * Double($1) } / group.order - 1) < 1e-12)")
    lines.append(ind + "// Every generator is an automorphism, and their orbits are `orbits`.")
    lines.append(ind + "let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })")
    lines.append(ind + "var root = Array(0 ..< graph.vertexCount)")
    lines.append(ind + "func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }")
    lines.append(ind + "for generator in group.generators {")
    lines.append(ind + "    #expect(Set(generator.images).count == graph.vertexCount)")
    edge = ("[$0.source, $0.target]" if g.directed else "[$0.u, $0.v]")
    norm = "" if g.directed else ".map { $0.sorted { index[$0]! < index[$1]! } }"
    lines.append(ind + "    let edges = graph.edges.map { %s }%s" % (edge, norm))
    ends = ("$0.source", "$0.target") if g.directed else ("$0.u", "$0.v")
    lines.append(ind + "    let moved = graph.edges.map { [generator.image(of: %s), generator.image(of: %s)] }%s" % (ends + (norm,)))
    lines.append(ind + "    #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\\.count))")
    lines.append(ind + "    for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }")
    lines.append(ind + "}")
    lines.append(ind + "let orbitOf = (0 ..< graph.vertexCount).map(find)")
    lines.append(ind + "#expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })")
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def test_for(n):
    if n >= 182:
        return automorphism_test(n)
    if is_trap(n):
        return trap_test(n)
    name = re.match(r"(\w+)", op(n)).group(1)
    if name in ref.MODES:
        return matching_test(n)
    if name == "weisfeilerLehmanGraphHash":
        return graph_hash_test(n)
    if name == "weisfeilerLehmanSubgraphHashes":
        return subgraph_hashes_test(n)
    return accessor_test(n)


def ids(*groups):
    return [n for n in PHASE1 if group(n) in groups and not is_trap(n)]


TRAPS = [n for n in PHASE1 if is_trap(n)]
FILES = [
    ("IsomorphismTests.swift", "Isomorphism", ids("Isomorphism"),
     "Isomorphism of undirected graphs (catalog IS-001 – IS-044): empty graphs, counts and degrees,\n"
     "// 1-WL-equivalent pairs (C6 and 2C3, Shrikhande and rook(4), CFI), the automorphism counts of\n"
     "// named graphs against relabelled copies, unique mappings of asymmetric graphs."),
    ("IsomorphismLoopTests.swift", "Isomorphism with self-loops and parallel edges", ids("Loops and parallel edges"),
     "Self-loops and parallel edges (catalog IS-045 – IS-056): a loop is an edge, multiplicities count."),
    ("IsomorphismDirectedTests.swift", "Directed isomorphism", ids("Directed"),
     "Directed graphs (catalog IS-057 – IS-070): arc direction is kept, so a 2-cycle is not two parallel\n"
     "// arcs; tournaments, directed loops, a directed multigraph."),
    ("IsomorphismColorTests.swift", "Isomorphism with vertex and edge colours", ids("Colours"),
     "Colours (catalog IS-071 – IS-086): vertex colours equal, edge colours as multisets per pair."),
    ("SubgraphIsomorphismTests.swift", "Subgraph isomorphism (induced)", ids("Subgraph isomorphism (induced)"),
     "Induced subgraph isomorphism (catalog IS-087 – IS-116): the receiver is the pattern; every pair\n"
     "// of pattern vertices has the multiplicity of its image pair, an empty pattern has one mapping."),
    ("MonomorphismTests.swift", "Monomorphism (non-induced)", ids("Monomorphism (non-induced)"),
     "Monomorphism (catalog IS-117 – IS-146): every pattern multiset is contained in its image pair's;\n"
     "// Hamiltonian cycles and paths, perfect matchings and cycles counted as pattern embeddings."),
    ("WeisfeilerLehmanTests.swift", "Weisfeiler–Leman hashes", ids("Weisfeiler–Leman"),
     "Weisfeiler–Leman (catalog IS-147 – IS-175): graph hashes compared within the process (their\n"
     "// values are not pinned), and the partitions of the per-vertex hashes after each round."),
    ("IsomorphismValueTests.swift", "Isomorphism values", ids("Isomorphism value"),
     "The mapping's accessors (catalog IS-177, IS-179, IS-180)."),
    ("IsomorphismPreconditionTests.swift", "Isomorphism preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call. Then the preconditions the catalog does\n"
     "// not list (extra_traps.swift)."),
]
if PHASE2:
    FILES.append(("AutomorphismGroupTests.swift", "Automorphism group (phase 2)", list(range(182, N + 1)),
                  "Phase 2 (catalog IS-182 – IS-233): orders and orbits of automorphismGroup(), generators\n"
                  "// checked to be automorphisms whose orbits are `orbits`. Written only with --phase2."))


def write(fname, suite, rows, comment_text):
    tests = [test_for(n) for n in rows]
    if fname == "IsomorphismPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    imports = ["GraphProtocols", "IsomorphismModule", "Multigraphs", "Testing"]
    if fname == "IsomorphismPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "IsomorphismPreconditionTests.swift" else ""
    out = ["// " + comment_text, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for line in body if line.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rows, comment_text in FILES:
    k = write(fname, suite, rows, comment_text)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == (N if PHASE2 else 181), rows_total
print("catalog rows", rows_total, "tests", total)
