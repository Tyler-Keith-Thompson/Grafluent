"""Generates the per-row Swift tests for catalog sections A-G from cases.md, with expected values
from ref.py (brute force = Hopcroft-Tarjan = NetworkX). Run from the repository root (OUTDIR
defaults to Tests/ConnectivityTests):
    uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/Connectivity/undirected/gen_tests.py [OUTDIR]
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ref  # noqa: E402

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent.parent.parent / "ConnectivityTests"

TITLES = {
    "CN-200": "the empty graph: not connected, nothing found (NetworkX, rustworkx, igraph, JGraphT)",
    "CN-201": "K₁: connected, not biconnected, no block, one 2-edge-connected component",
    "CN-202": "two isolated vertices (JGraphT, igraph, LEMON)",
    "CN-203": "K₂ is biconnected and its edge is a bridge (JGraphT, igraph, NetworkX, petgraph, rustworkx)",
    "CN-204": "K₂ and a third vertex is not biconnected (LEMON)",
    "CN-205": "rustworkx test_another_trivial_graph",
    "CN-206": "petgraph test_bridges, step 1",
    "CN-207": "petgraph test_bridges, step 2: a triangle",
    "CN-208": "petgraph test_bridges, step 3: a triangle and a 2-path",
    "CN-209": "petgraph test_bridges, step 4: the path closes a cycle",
    "CN-210": "petgraph's bridges doc example: e0, e1, e5",
    "CN-211": "NetworkX test_articulation_points_repetitions: 1 listed once",
    "CN-212": "NetworkX test_articulation_points_cycle and test_biconnected_components_cycle",
    "CN-213": "NetworkX test_is_biconnected: a triangle",
    "CN-214": "NetworkX test_empty_is_biconnected: five isolated vertices",
    "CN-215": "NetworkX test_empty_is_biconnected with one edge",
    "CN-216": "Boost connected_components.cpp (CLR p. 87): three components",
    "CN-217": "LEMON connectivity_test, 6 nodes: two components",
    "CN-218": "LEMON connectivity_test, 8 nodes: three components",
    "CN-219": "LEMON connectivity_test, 8 nodes with the five cut arcs",
    "CN-220": "NetworkX test_single_bridge: only (5, 6)",
    "CN-221": "NetworkX test_barbell_graph: only (2, 3)",
    "CN-222": "NetworkX test_multiedge_bridge: only (2, 3), a parallel pair is no bridge",
    "CN-223": "NetworkX TestHasBridges.test_multiedge_bridge: no bridges",
    "CN-224": "NetworkX test_bridges_multiple_components: every edge of two paths",
    "CN-225": "igraph igraph_bridges, 7 vertices: edges 3 and 7",
    "CN-226": "igraph igraph_bridges, disconnected with an isolated vertex: 0 1 2 13 14",
    "CN-227": "igraph igraph_bridges with multi-edges and a self-loop: edge 2",
    "CN-228": "rustworkx test_tree: every edge is a bridge",
    "CN-229": "rustworkx test_cycle_no_bridges: a 100-cycle",
    "CN-230": "JGraphT testGithubIssueBug798: cut point 0, bridge 0–3, two blocks",
    "CN-231": "NetworkX test_tarjan_bridge (Tarjan 1974): bridges (4, 8), (3, 5), (3, 17)",
    "CN-232": "NetworkX test_bridge_cc: the 2-edge-connected components",
    "CN-233": "NetworkX bridge_components doc example: barbell_graph(5, 0)",
    "CN-234": "NetworkX test_triangles: two triangles joined by 11–21",
    "CN-235": "NetworkX test_biconnected_components1: points 4, 6, 7, 8, 9 and 7 blocks",
    "CN-236": "NetworkX test_biconnected_components2: points C, E, G",
    "CN-237": "NetworkX test_biconnected_components2 with I–J written twice: the copy joins the big block",
    "CN-238": "NetworkX test_barbell: barbell_graph(8, 4) with a tail and a cycle, 11 blocks",
    "CN-239": "NetworkX test_barbell with 2–17: points 7, 20, 21, 22",
    "CN-240": "NetworkX test_biconnected_karate: point 0, three blocks",
    "CN-241": "NetworkX test_biconnected_eppstein G1: biconnected",
    "CN-242": "NetworkX test_biconnected_eppstein G2: four blocks",
    "CN-243": "JGraphT testWikiGraph: points 4, 5, 6, 7, 9 and five bridges",
    "CN-244": "JGraphT testMultiGraph: a loop and a parallel pair",
    "CN-245": "JGraphT testMultiGraph2: every edge twice, same points and blocks, no bridges",
    "CN-246": "JGraphT testLinearGraph: n − 2 points on a path",
    "CN-247": "JGraphT testBiconnected: the 6-cycle",
    "CN-248": "JGraphT testNotBiconnected: two points",
    "CN-249": "JGraphT testConnectedComponents1: two components",
    "CN-250": "JGraphT ConnectivityInspectorTest pseudograph: not connected",
    "CN-251": "JGraphT testIsGraphConnected: connected",
    "CN-252": "petgraph art_two_connected_components: B and E",
    "CN-253": "petgraph art_linear_chain: B and C",
    "CN-254": "petgraph art_star_graph: the center",
    "CN-255": "petgraph art_clique: none",
    "CN-256": "petgraph art_simple1: B",
    "CN-257": "petgraph art_disconnected_graph: B",
    "CN-258": "petgraph art_3x3_grid: none",
    "CN-259": "petgraph art_simple2: B and D",
    "CN-260": "Boost biconnected_components.cpp: 4 blocks, 3 articulation points",
    "CN-261": "Boost biconnected_components_test.cpp: the 4-vertex graph",
    "CN-262": "igraph igraph_biconnected_components: points 2 and 5, an isolated vertex",
    "CN-263": "igraph igraph_is_biconnected: two cycles sharing a vertex",
    "CN-264": "igraph igraph_is_biconnected: a 10-ring",
    "CN-265": "igraph igraph_is_biconnected: a triangle, a pendant and isolated vertices",
    "CN-266": "igraph igraph_is_biconnected: a triangle with an ear",
    "CN-267": "igraph igraph_is_biconnected: a triangle and a 2-path",
    "CN-268": "igraph igraph_is_biconnected: two disjoint cycles",
    "CN-269": "igraph igraph_is_biconnected: a cycle and an isolated vertex is not biconnected",
    "CN-270": "igraph igraph_is_biconnected: the first vertex is the articulation point",
    "CN-271": "rustworkx TestBiconnected.test_graph: points 4 and 5, 4 blocks",
    "CN-272": "rustworkx test_barbell_graph: points 2 and 3",
    "CN-273": "rustworkx test_disconnected_graph: two barbells",
    "CN-274": "rustworkx test_biconnected_graph: one block of 11 edges",
    "CN-275": "NetworkX TestConnected: a grid, a lollipop and a house",
    "CN-276": "NetworkX test_is_connected: a 4 × 4 grid",
    "CN-277": "NetworkX test_is_connected: two vertices, no edge",
    "CN-278": "LEMON connectivity_test, 8 nodes as bi-node and bi-edge components: no bridge",
    "CN-279": "LEMON connectivity_test, 6 nodes: no articulation point",
    "CN-280": "a lone self-loop is in no block and makes no articulation point",
    "CN-281": "a parallel pair is one block, biconnected and bi-edge-connected, and no bridge",
    "CN-282": "three parallel edges are one block",
    "CN-283": "parallelPath: the doubled edge is no bridge",
    "CN-284": "a self-loop at a cut vertex keeps it one and is in no block",
    "CN-285": "loopAndPath: a loop on the end of a path makes no articulation point",
    "CN-286": "a loop and one edge: still biconnected, the loop makes no cut vertex",
    "CN-287": "k3WithLoop: the loop changes nothing",
    "CN-288": "petgraphUndirected: doubled edges and a loop at a",
    "CN-289": "vertices whose only edges are loops are in no block",
    "CN-290": "a doubled middle edge on a path",
    "CN-291": "the parallel copy of a tree edge written far from it: skip the parent edge, not the parent vertex",
    "CN-292": "the parallel copy of the root's first tree edge, written last",
    "CN-293": "networkXIJK, String vertices: a loop at K",
    "CN-294": "petgraphUndirected, String vertices",
    "CN-295": "two loops and a parallel pair on two vertices",
    "CN-296": "a digraph's opposite arcs through .undirected are parallel edges, so not bridges",
    "CN-297": "doubling every edge of CN-238: no bridges, the same points, every block doubled",
    "CN-298": "a loop at every vertex of a path",
    "CN-299": "the loop written between a tree edge and its parallel copy",
    "CN-300": "the path P₆",
    "CN-301": "the cycle C₆",
    "CN-302": "the star K₁,₅",
    "CN-303": "K₅",
    "CN-304": "K₂,₃",
    "CN-305": "a bowtie is 2-edge-connected but not biconnected",
    "CN-306": "a theta graph",
    "CN-307": "the ladder L₄",
    "CN-308": "the wheel W₆",
    "CN-309": "a chain of four triangles",
    "CN-310": "a lollipop: K₄ with a 3-edge tail",
    "CN-311": "a caterpillar",
    "CN-312": "a forest of three trees and an isolated vertex",
    "CN-313": "the 3 × 4 grid",
    "CN-314": "the 1 × 5 grid is a path",
    "CN-315": "the first vertex is a cut vertex in three blocks",
    "CN-316": "a cycle with a chord and a pendant",
    "CN-317": "a one-edge block between two cut vertices",
    "CN-318": "nested blocks: cut vertices in three blocks",
    "CN-319": "blocks are ordered by smallest position, not by search completion",
    "CN-320": "k3",
    "CN-321": "path4",
    "CN-322": "cycle5",
    "CN-323": "k4",
    "CN-324": "house",
    "CN-325": "petersen: 3-connected",
    "CN-326": "cube: 3-connected",
    "CN-327": "components7",
    "CN-328": "isolatedVertices",
    "CN-329": "networkXABCD, String vertices: the isolated G, J, K come first",
    "CN-330": "isolated vertices around one block are in no block",
    "CN-331": "an isolated vertex listed last",
    "CN-332": "two components, each with a cut vertex",
    "CN-333": "a loop-only component next to a tree",
    "CN-334": "a component of parallel edges next to a bridge",
    "CN-335": "components interleaved in vertices order",
    "CN-336": "a tree, a cycle, a bowtie, a loop-only vertex and an isolated vertex",
    "CN-337": "two copies of CN-235",
    "CN-338": "20 isolated vertices and one edge between the last two",
    "CN-339": "gap4 read as written: every arc an edge, opposite arcs parallel",
}

SECTIONS = [
    ("UndirectedComponentsTests.swift", "UndirectedComponentsTests", "Undirected connectivity basics", 200, 219,
     "§A: the basic cases every entry point agrees on — the empty graph, K₁, K₂, a few vertices, and\n"
     "// small graphs ported from NetworkX, petgraph, rustworkx, Boost and LEMON"),
    ("BridgeTests.swift", "BridgeTests", "Bridges and 2-edge-connected components", 220, 234,
     "§B: bridges and 2-edge-connected components, ported from NetworkX, igraph, rustworkx and JGraphT"),
    ("BiconnectedComponentTests.swift", "BiconnectedComponentTests", "Articulation points and blocks", 235, 279,
     "§C: articulation points, blocks and the block–cut tree, ported from NetworkX, JGraphT, petgraph,\n"
     "// Boost, igraph, rustworkx and LEMON"),
    ("UndirectedSelfLoopAndParallelEdgeTests.swift", "UndirectedSelfLoopAndParallelEdgeTests", "Undirected parallel edges and self-loops", 280, 299,
     "§D: parallel edges and self-loops. A parallel pair is never a bridge and both copies share a\n"
     "// block; a self-loop is never a bridge, never makes an articulation point and is in no block"),
    ("UndirectedFamilyTests.swift", "UndirectedFamilyTests", "Forests, paths, cycles and complete graphs", 300, 319,
     "§E: graph families — paths, cycles, stars, complete and complete bipartite graphs, grids, wheels,\n"
     "// chains of blocks — and the canonical block order"),
    ("UndirectedFixtureTests.swift", "UndirectedFixtureTests", "Undirected connectivity on the named fixtures", 320, 329,
     "§F: the named UndirectedFixture graphs"),
    ("UndirectedDisconnectedTests.swift", "UndirectedDisconnectedTests", "Disconnected undirected graphs", 330, 339,
     "§G: disconnected graphs — isolated vertices, loop-only components, interleaved components"),
]


def swift_atom(v):
    return f'"{v}"' if isinstance(v, str) else str(v)


def is_run(xs):
    return len(xs) >= 6 and all(isinstance(x, int) for x in xs) and xs == list(range(xs[0], xs[0] + len(xs)))


def lit(v, compress=True):
    """A Swift literal for an int/str or nested list; runs of 6+ consecutive ints become Array(a ... b)."""
    if isinstance(v, list):
        if compress and is_run(v):
            return f"Array({v[0]} ... {v[-1]})"
        return "[" + ", ".join(lit(x, compress) for x in v) + "]"
    return swift_atom(v)


def has_call(s):
    return "Array(" in s


def range_lit(vs):
    if vs and all(isinstance(x, int) for x in vs) and vs == list(range(vs[0], vs[0] + len(vs))) and len(vs) >= 3:
        return f"{vs[0]} ... {vs[-1]}"
    return lit(vs, compress=False)


def has_repeats(es):
    seen = set()
    for u, v in es:
        k = frozenset((u, v))
        if k in seen:
            return True
        seen.add(k)
    return False


def first_appearance(es):
    out, seen = [], set()
    for e in es:
        for x in e:
            if x not in seen:
                seen.add(x)
                out.append(x)
    return out


def tokens(spec):
    return re.findall(r"[A-Za-z]+\([^)]*\)|\S+", spec)


def code_edges(spec):
    """Swift statements building `pairs` for a long edge list, following the catalog's notation."""
    lines = ["var pairs: [(Int, Int)] = []"]
    pending = []

    def flush():
        if pending:
            lines.append("pairs += [" + ", ".join(f"({a}, {b})" for a, b in pending) + "]")
            pending.clear()

    for tok in tokens(spec):
        m = re.fullmatch(r"([A-Za-z]+)\((.*)\)", tok)
        if not m:
            a, b = tok.split("-")
            pending.append((int(a), int(b)))
            continue
        kind, body = m.groups()
        xs = ref._args(body)
        if kind == "K" and xs == list(range(xs[0], xs[-1] + 1)):
            flush()
            lines.append(f"for u in {xs[0]} ..< {xs[-1]} {{ for v in u + 1 ... {xs[-1]} {{ pairs.append((u, v)) }} }}")
        elif kind in ("P", "C") and xs == list(range(xs[0], xs[-1] + 1)) and len(xs) >= 5:
            flush()
            lines.append(f"for i in {xs[0]} ..< {xs[-1]} {{ pairs.append((i, i + 1)) }}")
            if kind == "C":
                lines.append(f"pairs.append(({xs[-1]}, {xs[0]}))")
        elif kind == "P":
            pending.extend(zip(xs, xs[1:]))
        elif kind == "C":
            pending.extend(list(zip(xs, xs[1:])) + [(xs[-1], xs[0])])
        else:
            raise SystemExit(f"no code form for {tok}")
    flush()
    return lines


def camel(title, cid):
    words = re.findall(r"[A-Za-z0-9]+", title.replace("'s", "").replace("₁", "1").replace("₂", "2").replace("₃", "3").replace("₄", "4").replace("₅", "5").replace("₆", "6"))
    words = [w for w in words if w.lower() not in ("the", "a", "an", "and", "of", "is", "by", "to")][:6]
    if not words:
        return "case" + cid[3:]
    name = words[0].lower() + "".join(w[:1].upper() + w[1:] for w in words[1:])
    if name[0].isdigit():
        name = "n" + name
    return name


USED = set()


def gen_case(cid, spec, src):
    vs, es = ref.parse_graph(spec)
    r = ref.compute(vs, es)
    ref.laws(vs, es, r)
    title = TITLES[cid]
    strings = any(isinstance(v, str) for v in vs)
    V = "String" if strings else "Int"
    loops = any(u == v for u, v in es)
    tags = []
    if spec.startswith("fixture:"):
        tags.append(".fixture")
    if loops:
        tags.append(".selfLoops")
    tag = f", .tags({', '.join(tags)})" if tags else ""
    body = []
    graphs = []
    small = len(vs) <= 40 and len(es) <= 40
    # Construction.
    if spec.startswith("fixture:"):
        name = spec[len("fixture:"):]
        if name.startswith("s:"):
            body.append(f"let fixture = UndirectedFixture<String>.{name[2:]}")
        else:
            body.append(f"let fixture = UndirectedFixture<Int>.{name}")
        graphs.append("ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)")
        if not has_repeats(es):
            graphs.append("UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)")
    elif spec.startswith("realworld:"):
        name = spec[len("realworld:"):]
        body.append(f"let fixture = DirectedFixture<Int>.{name}")
        body.append("let edges = fixture.edges.map { UndirectedEdge($0.source, $0.target) }")
        graphs.append(f"ReferencePseudograph(vertices: 0 ..< {len(vs)}, edges: edges)")
    else:
        body.append(f"// {spec}")
        if len(es) == 0:
            body.append(f"let edges: [UndirectedEdge<{V}>] = []")
        elif len(es) <= 48:
            pairs = ", ".join(f"({swift_atom(a)}, {swift_atom(b)})" for a, b in es)
            body.append(f"let edges = [{pairs}].map {{ UndirectedEdge($0.0, $0.1) }}")
        else:
            body.extend(code_edges(spec))
            body.append("let edges = pairs.map { UndirectedEdge($0.0, $0.1) }")
        listed = "" if vs == first_appearance(es) else f"vertices: {range_lit(vs)}, "
        graphs.append(f"ReferencePseudograph({listed}edges: edges)")
        if not has_repeats(es):
            graphs.append(f"UndirectedAdjacencyList({listed}edges: edges)")
        if cid == "CN-296":
            graphs.append("AdjacencyList(edges: [(0, 1), (1, 0), (1, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }).undirected")
    if len(es) > 48 and not spec.startswith(("fixture:", "realworld:")):
        # check the generated code reproduces the notation
        pass

    # Expectations.
    chk = []

    def expect_list(expr, value, compress=True, elem=V):
        if value == []:
            chk.append(f"#expect({expr.replace('.map(Array.init)', '')}.isEmpty)")
            return
        s = lit(value, compress)
        if has_call(s):
            chk.append(f"let expected{len(chk)}: [[{elem}]] = {s}" if isinstance(value[0], list) else f"let expected{len(chk)}: [{elem}] = {s}")
            chk.append(f"#expect({expr} == expected{len(chk) - 1})")
        else:
            chk.append(f"#expect({expr} == {s})")

    def expect_bool(expr, b):
        chk.append(f"#expect({'' if b else '!'}{expr})")

    expect_list("g.connectedComponents().map(Array.init)", r["cc"])
    expect_bool("g.isConnected", r["conn"])
    if r["br"] == []:
        chk.append("#expect(g.bridges().isEmpty)")
    else:
        chk.append(f"#expect(g.bridges() == {lit(r['br'], False)})")
    expect_bool("g.hasBridges", r["hasbr"])
    expect_list("g.articulationPoints()", r["ap"], compress=False)
    chk.append("let blocks = g.biconnectedComponents()")
    chk.append(f"#expect(blocks.count == {r['nbcc']})" if r["nbcc"] else "#expect(blocks.isEmpty)")
    expect_list("blocks.map(Array.init)", r["bcc"], elem="Int")
    expect_list("blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }", r["bccv"])
    expect_bool("g.isBiconnected", r["bic"])
    expect_list("g.biEdgeConnectedComponents().map(Array.init)", r["becc"])
    expect_bool("g.isBiEdgeConnected", r["bec"])
    chk.append("let tree = g.blockCutTree()")
    chk.append("#expect(tree.blocks == blocks)")
    expect_list("tree.articulationPoints", r["ap"], compress=False)
    if r["bct"]:
        chk.append(f"#expect(blocks.indices.map {{ tree.articulationPoints(ofBlock: $0).map {{ tree.articulationPoints[$0] }} }} == {lit(r['bct'], False)})")
    tree_edges = sum(len(x) for x in r["bct"])
    chk.append(f"#expect(tree.edgeCount == {tree_edges})")
    if small:
        label = {}
        for b, block in enumerate(r["bcc"]):
            for k in block:
                label[k] = b
        if es:
            labels = ", ".join(str(label[k]) if k in label else "nil" for k in range(len(es)))
            chk.append(f"#expect(g.edges.indices.map {{ blocks.component(ofEdgeAt: $0) }} == [{labels}])")
        containing = {v: [b for b, bv in enumerate(r["bccv"]) if v in bv] for v in vs}
        if vs:
            chk.append(f"#expect(g.vertices.map {{ Array(blocks.components(containing: $0)) }} == {lit([containing[v] for v in vs], False)})")
            ap_index = {v: i for i, v in enumerate(r["ap"])}
            nodes = []
            for v in vs:
                if v in ap_index:
                    nodes.append(f".articulationPoint({ap_index[v]})")
                elif containing[v]:
                    nodes.append(f".block({containing[v][0]})")
                else:
                    nodes.append("nil")
            chk.append(f"let nodes: [BlockCutTree<G>.Node?] = [{', '.join(nodes)}]")
            chk.append("#expect(g.vertices.map { tree.node(of: $0) } == nodes)")
        if r["ap"]:
            blocks_of = [[b for b, bv in enumerate(r["bccv"]) if a in bv] for a in r["ap"]]
            chk.append(f"#expect(tree.articulationPoints.indices.map {{ Array(tree.blocks(ofArticulationPoint: $0)) }} == {lit(blocks_of, False)})")

    out = []
    out.append(f'    @Test("{cid} {title}"{tag})')
    name = camel(title, cid)
    while name in USED:
        name += cid[3:]
    USED.add(name)
    out.append(f"    func {name}() {{")
    for line in body:
        out.append(f"        {line}")
    out.append(f"        func check<G: Graph<{V}>>(_ g: G) where G.Edges.Index == Int {{")
    for line in chk:
        out.append(f"            {line}")
    out.append("        }")
    for g in graphs:
        out.append(f"        check({g})")
    out.append("    }")
    return "\n".join(out), (vs, es)


def verify_code(spec, es):
    """The code form builds the same edges as the notation."""
    lines = code_edges(spec)
    pairs = []
    for line in lines[1:]:
        m = re.fullmatch(r"for u in (\d+) \.\.< (\d+) \{ for v in u \+ 1 \.\.\. (\d+) \{ pairs.append\(\(u, v\)\) \} \}", line)
        if m:
            a, b, c = map(int, m.groups())
            pairs += [(u, v) for u in range(a, b) for v in range(u + 1, c + 1)]
            continue
        m = re.fullmatch(r"for i in (\d+) \.\.< (\d+) \{ pairs.append\(\(i, i \+ 1\)\) \}", line)
        if m:
            a, b = map(int, m.groups())
            pairs += [(i, i + 1) for i in range(a, b)]
            continue
        m = re.fullmatch(r"pairs.append\(\((\d+), (\d+)\)\)", line)
        if m:
            pairs.append(tuple(map(int, m.groups())))
            continue
        m = re.fullmatch(r"pairs \+= \[(.*)\]", line)
        if m:
            pairs += [tuple(map(int, p)) for p in re.findall(r"\((\d+), (\d+)\)", m.group(1))]
            continue
        raise SystemExit(line)
    assert pairs == es, (spec, pairs[:5], es[:5])


def main():
    rows = {cid: (spec, None) for cid, spec, _ in ref.catalog()}
    counts = {}
    for fname, struct, suite, lo, hi, blurb in SECTIONS:
        tests = []
        USED.clear()
        imports = ["AdjacencyListModule", "Connectivity", "GraphProtocols", "GrafluentTestSupport", "Testing"]
        for n in range(lo, hi + 1):
            cid = f"CN-{n}"
            spec = rows[cid][0]
            if spec is None:
                continue
            code, (vs, es) = gen_case(cid, spec, None)
            if len(es) > 48 and not spec.startswith(("fixture:", "realworld:")):
                verify_code(spec, es)
            tests.append(code)
        counts[fname] = len(tests)
        header = (
            f"// {blurb}.\n"
            "// Each case runs on the ReferencePseudograph in written order, and on an UndirectedAdjacencyList\n"
            "// built in the same order when no edge repeats, so positions and vertices order are the written\n"
            "// ones and every value is exact. Expected values come from the catalog's reference (brute force\n"
            "// from the definitions, an iterative Hopcroft–Tarjan and NetworkX 3.7). Case IDs (CN-nnn) refer to\n"
            "// the catalog; see README.md.\n\n"
        )
        text = header + "\n".join(f"import {m}" for m in imports) + "\n\n"
        text += f'@Suite("{suite}")\nstruct {struct} {{\n' + "\n\n".join(tests) + "\n}\n"
        (OUT / fname).write_text(text)
    print(counts)


if __name__ == "__main__":
    main()
