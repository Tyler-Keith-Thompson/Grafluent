"""Independent reference for the undirected half of Connectivity (catalog cases.md, CN-200 …).

Run:  uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/Connectivity/undirected/ref.py
      ... python3 ref.py --emit CN-231      print every computed value for one case
      ... python3 ref.py --quick            skip the slow random and stress sections

Everything here is computed two ways, neither of them the algorithm under test's shape:

* brute force, straight from the definitions:
  - components: breadth-first search in `vertices` order;
  - a bridge is a non-loop edge whose removal increases the number of components;
  - an articulation point is a vertex whose removal increases the number of components;
  - blocks: two non-loop edges with a common end w are in one block iff their far ends are
    connected in G − w (parallel edges trivially); blocks are the transitive closure, and a
    self-loop is in no block;
  - 2-edge-connected components: u ~ v iff u and v are connected in G − e for every edge e;
  - isBiconnected: ≥ 2 vertices, connected, no articulation point;
  - isBiEdgeConnected: ≥ 2 vertices, connected, no bridge;
  - block–cut tree: for each block, the articulation points it contains;
* an iterative Hopcroft–Tarjan that skips the parent EDGE (by position), never the parent
  vertex, with an edge stack for blocks and a vertex stack for 2-edge-connected components:
  the algorithm api.md proposes, checked against brute force on every case and on random
  multigraphs, and used alone on the stress sizes.

Then NetworkX 3.7 cross-checks every case (MultiGraph for bridges; the simple collapse for
articulation points and blocks, which NetworkX defines on simple graphs).

Canonical orders (api.md): components and 2-edge-connected components by first vertex in
`vertices` order, members in `vertices` order; bridges by ascending position; articulation points
in `vertices` order; blocks by their smallest edge position, edges ascending; block vertices in
`vertices` order.
"""

import random
import re
import sys
from collections import deque
from pathlib import Path

import networkx as nx

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent.parent

# --------------------------------------------------------------------------------------------
# Graph model: (vertices, edges). vertices is a list in `vertices` order, edges a list of (u, v)
# in position order. Vertex order: listed vertices first, then endpoints by first appearance,
# exactly as ReferencePseudograph(vertices:edges:) and UndirectedAdjacencyList insertion order.
# --------------------------------------------------------------------------------------------


def make_graph(listed, edges):
    vs, seen = [], set()
    for v in list(listed) + [x for e in edges for x in e]:
        if v not in seen:
            seen.add(v)
            vs.append(v)
    return vs, list(edges)


# ------------------------------- fixtures (transcribed) --------------------------------------
# Transcribed from Tests/GrafluentTestSupport/UndirectedFixtures.swift, builder loops included.

def _karate():
    e = []
    for v in [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 17, 19, 21, 31]: e.append((0, v))
    for v in [2, 3, 7, 13, 17, 19, 21, 30]: e.append((1, v))
    for v in [3, 7, 8, 9, 13, 27, 28, 32]: e.append((2, v))
    for v in [7, 12, 13]: e.append((3, v))
    for v in [6, 10]: e.append((4, v))
    for v in [6, 10, 16]: e.append((5, v))
    e.append((6, 16))
    for v in [30, 32, 33]: e.append((8, v))
    e.append((9, 33)); e.append((13, 33))
    for u in [14, 15, 18]:
        for v in [32, 33]: e.append((u, v))
    e.append((19, 33))
    for u in [20, 22]:
        for v in [32, 33]: e.append((u, v))
    for v in [25, 27, 29, 32, 33]: e.append((23, v))
    for v in [25, 27, 31]: e.append((24, v))
    e.append((25, 31))
    for v in [29, 33]: e.append((26, v))
    e.append((27, 33))
    for v in [31, 33]: e.append((28, v))
    for u in [29, 30, 31]:
        for v in [32, 33]: e.append((u, v))
    e.append((32, 33))
    return [], e


FIXTURES = {
    "empty": ([], []),
    "trivial": ([0], []),
    "singleSelfLoop": ([], [(0, 0)]),
    "isolatedVertices": (list(range(10)), []),
    "k3": ([], [(0, 1), (0, 2), (1, 2)]),
    "k3WithLoop": ([], [(0, 1), (0, 2), (1, 2), (0, 0)]),
    "loopAndPath": ([], [(0, 0), (0, 1), (1, 2)]),
    "petgraphUndirected": ([], [(0, 1), (0, 2), (2, 0), (0, 0), (1, 2), (1, 0), (0, 3)]),
    "components7": (list(range(7)), [(0, 1), (1, 2), (3, 4)]),
    "path4": ([], [(0, 1), (1, 2), (2, 3)]),
    "cycle5": ([], [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4)]),
    "k4": ([], [(u, v) for u in range(4) for v in range(u + 1, 4)]),
    "house": ([], [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 4)]),
    "petersen": ([], [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9),
                      (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]),
    "cube": ([], [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6),
                  (5, 7), (6, 7)]),
    "karate": _karate(),
    "parallelPath": ([], [(0, 1), (1, 2), (1, 2)]),
    "s:networkXABCD": (["G", "J", "K"], [("A", "B"), ("A", "C"), ("B", "D"), ("C", "B"), ("C", "D")]),
    "s:networkXIJK": ([], [("I", "J"), ("K", "K"), ("J", "K")]),
    "s:petgraphUndirected": ([], [("a", "b"), ("a", "c"), ("c", "a"), ("a", "a"), ("b", "c"), ("b", "a"),
                                  ("a", "d")]),
}


def check_fixture_transcription():
    """The transcribed fixtures agree with the Swift file's declared edge counts and degrees."""
    text = (REPO / "Tests/GrafluentTestSupport/UndirectedFixtures.swift").read_text()
    for name in ["k3", "k3WithLoop", "loopAndPath", "petgraphUndirected", "path4", "cycle5", "house",
                 "petersen", "cube", "parallelPath"]:
        block = text.split(f"public static let {name} =")[1].split("public static let")[0]
        pairs = [(int(a), int(b)) for a, b in re.findall(r"UndirectedEdge\((\d+), (\d+)\)", block)]
        assert pairs == FIXTURES[name][1], (name, pairs)
    # karate: degree list from the file
    block = text.split("public static let karate =")[1]
    degs = [int(x) for x in re.search(r"byVertex\(\[(.*?)\]\)", block, re.S).group(1).replace("\n", " ").replace(",", " ").split()]
    vs, es = make_graph(*FIXTURES["karate"])
    d = {v: 0 for v in vs}
    for u, v in es:
        d[u] += 1; d[v] += 1
    assert [d[i] for i in range(34)] == degs and len(es) == 78


def realworld(name):
    text = (REPO / "Tests/GrafluentTestSupport/RealWorldFixtures.swift").read_text()
    block = text.split(f"public static let {name}:")[1].split("public static let")[0]
    def arr(label):
        body = re.search(rf"let {label}: \[Int\] = \[(.*?)\]", block, re.S).group(1)
        return [int(x) for x in body.replace(",", " ").split()]
    s, t = arr("sources"), arr("targets")
    n = int(re.search(r"vertices: Array\(0 \.\.< (\d+)\)", block).group(1))
    return list(range(n)), list(zip(s, t))


# ------------------------------- the graph mini-language -------------------------------------

def _atom(tok):
    tok = tok.strip()
    return int(tok) if re.fullmatch(r"\d+", tok) else tok


def _args(body):
    out = []
    for part in body.split(","):
        part = part.strip()
        m = re.fullmatch(r"(\d+)\.\.(\d+)", part)
        if m:
            out.extend(range(int(m.group(1)), int(m.group(2)) + 1))
        elif part:
            out.append(_atom(part))
    return out


def parse_graph(spec):
    spec = spec.strip()
    if spec.startswith("fixture:"):
        return make_graph(*FIXTURES[spec[len("fixture:"):]])
    if spec.startswith("realworld:"):
        name, _, mode = spec[len("realworld:"):].partition("/")
        vs, es = realworld(name)
        if mode == "simple":  # UndirectedAdjacencyList: one edge per unordered pair, loops kept once
            seen, out = set(), []
            for u, v in es:
                k = frozenset((u, v))
                if k not in seen:
                    seen.add(k); out.append((u, v))
            es = out
        return make_graph(vs, es)
    listed, edges = [], []
    m = re.match(r"\[(.*?)\]", spec)
    if m:
        listed = _args(m.group(1))
        spec = spec[m.end():]
    for tok in re.findall(r"[A-Za-z]+\([^)]*\)|\S+", spec):
        m = re.fullmatch(r"([A-Za-z]+)\((.*)\)", tok)
        if m and m.group(1) in ("P", "Pd", "C", "K", "S", "T", "grid", "ladder"):
            kind, body = m.group(1), m.group(2)
            if kind == "grid" or kind == "ladder":
                r, c = (int(x) for x in body.split(",")) if kind == "grid" else (2, int(body))
                listed += [i * c + j for i in range(r) for j in range(c)]
                for i in range(r):
                    for j in range(c):
                        if j + 1 < c: edges.append((i * c + j, i * c + j + 1))
                        if i + 1 < r: edges.append((i * c + j, (i + 1) * c + j))
                continue
            if kind == "T":
                k = int(body)
                edges += [e for i in range(k) for e in ((2 * i, 2 * i + 1), (2 * i + 1, 2 * i + 2), (2 * i + 2, 2 * i))]
                continue
            if kind == "S":
                center, _, rest = body.partition(";")
                c = _atom(center)
                edges += [(c, x) for x in _args(rest)]
                continue
            xs = _args(body)
            if kind == "P":
                edges += list(zip(xs, xs[1:]))
            elif kind == "Pd":
                edges += [e for pair in zip(xs, xs[1:]) for e in (pair, pair)]
            elif kind == "C":
                edges += list(zip(xs, xs[1:])) + [(xs[-1], xs[0])]
            else:
                edges += [(xs[i], xs[j]) for i in range(len(xs)) for j in range(i + 1, len(xs))]
            continue
        a, b = tok.split("-")
        edges.append((_atom(a), _atom(b)))
    return make_graph(listed, edges)


# ------------------------------- brute force -------------------------------------------------

def components(vs, es, drop_vertex=None, drop_edge=None):
    """Components in canonical order (first vertex in `vertices` order, members in that order)."""
    adj = {v: [] for v in vs if v != drop_vertex}
    for k, (u, v) in enumerate(es):
        if k == drop_edge or drop_vertex in (u, v):
            continue
        adj[u].append(v); adj[v].append(u)
    label, comps = {}, []
    for s in adj:
        if s in label:
            continue
        label[s] = len(comps)
        q = deque([s])
        while q:
            x = q.popleft()
            for y in adj[x]:
                if y not in label:
                    label[y] = len(comps); q.append(y)
        comps.append(None)
    groups = [[] for _ in comps]
    for v in vs:
        if v != drop_vertex:
            groups[label[v]].append(v)
    return groups, label


def brute(vs, es):
    cc, label = components(vs, es)
    c0 = len(cc)
    br = [k for k, (u, v) in enumerate(es) if u != v and len(components(vs, es, drop_edge=k)[0]) > c0]
    minus = {x: components(vs, es, drop_vertex=x)[1] for x in vs}
    ap = [x for x in vs if len(set(minus[x].values())) > c0]
    # blocks: union of adjacent non-loop edges whose far ends are joined in G - w
    parent = list(range(len(es)))
    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]; a = parent[a]
        return a
    ends = {v: [] for v in vs}
    for k, (u, v) in enumerate(es):
        if u != v:
            ends[u].append(k); ends[v].append(k)
    for w in vs:
        inc = ends[w]
        for i in range(len(inc)):
            for j in range(i + 1, len(inc)):
                e, f = es[inc[i]], es[inc[j]]
                a = e[0] if e[1] == w else e[1]
                b = f[0] if f[1] == w else f[1]
                if a == b or minus[w][a] == minus[w][b]:
                    parent[find(inc[i])] = find(inc[j])
    blocks = {}
    for k, (u, v) in enumerate(es):
        if u != v:
            blocks.setdefault(find(k), []).append(k)
    bcc = sorted(blocks.values(), key=lambda b: b[0])
    # 2-edge-connected components
    labels = [label] + [components(vs, es, drop_edge=k)[1] for k, (u, v) in enumerate(es) if u != v]
    key = {v: tuple(l[v] for l in labels) for v in vs}
    groups, order = {}, []
    for v in vs:
        if key[v] not in groups:
            groups[key[v]] = []; order.append(key[v])
        groups[key[v]].append(v)
    becc = [groups[k] for k in order]
    return finish(vs, es, cc, br, ap, bcc, becc)


def finish(vs, es, cc, br, ap, bcc, becc):
    pos = {v: i for i, v in enumerate(vs)}
    apset = set(ap)
    bccv = [sorted({x for k in b for x in es[k]}, key=pos.get) for b in bcc]
    n = len(vs)
    return {
        "cc": cc, "ncc": len(cc), "conn": len(cc) == 1,
        "br": br, "nbr": len(br), "hasbr": bool(br),
        "ap": ap, "nap": len(ap),
        "bcc": bcc, "bccv": bccv, "nbcc": len(bcc),
        "bic": n >= 2 and len(cc) == 1 and not ap,
        "becc": becc, "nbecc": len(becc),
        "bec": n >= 2 and len(cc) == 1 and not br,
        "bct": [[x for x in b if x in apset] for b in bccv],
    }


# ------------------------------- iterative Hopcroft–Tarjan (the proposal) --------------------

def hopcroft_tarjan(vs, es, skip_parent_vertex=False, push_loops=False):
    """One iterative DFS over vertex numbers in `vertices` order, incident edges in
    ReferencePseudograph order (each edge at its u end, then its v end, by position). Skips
    exactly the parent edge's position; a back edge is pushed once, from its lower end; a
    self-loop is never pushed and never lowers anything."""
    n = len(vs)
    num = {v: i for i, v in enumerate(vs)}
    inc = [[] for _ in range(n)]  # (neighbor, position)
    for k, (u, v) in enumerate(es):
        inc[num[u]].append((num[v], k))
        inc[num[v]].append((num[u], k))
    disc = [-1] * n
    low = [0] * n
    parent_edge = [-1] * n
    is_ap = [False] * n
    is_bridge = [False] * len(es)
    block_of = [-1] * len(es)
    becc_of = [-1] * n
    nblocks = nbecc = 0
    t = 0
    estack, vstack = [], []
    pushed_loops = set()
    for root in range(n):
        if disc[root] >= 0:
            continue
        disc[root] = low[root] = t; t += 1
        vstack.append(root)
        stack = [(root, 0)]
        root_children = 0
        while stack:
            v, i = stack[-1]
            if i < len(inc[v]):
                stack[-1] = (v, i + 1)
                w, k = inc[v][i]
                if push_loops and w == v and k not in pushed_loops:
                    pushed_loops.add(k); estack.append(k)
                    continue
                if w == v:
                    continue
                if k == parent_edge[v] or (skip_parent_vertex and parent_edge[v] >= 0
                                           and w in (num[es[parent_edge[v]][0]], num[es[parent_edge[v]][1]])):
                    continue
                if disc[w] < 0:
                    parent_edge[w] = k
                    disc[w] = low[w] = t; t += 1
                    estack.append(k); vstack.append(w)
                    stack.append((w, 0))
                    if v == root:
                        root_children += 1
                elif disc[w] < disc[v]:
                    estack.append(k)
                    low[v] = min(low[v], disc[w])
                continue
            stack.pop()
            if not stack:
                break
            p = stack[-1][0]
            low[p] = min(low[p], low[v])
            k = parent_edge[v]
            if low[v] > disc[p]:
                is_bridge[k] = True
                while True:
                    x = vstack.pop(); becc_of[x] = nbecc
                    if x == v: break
                nbecc += 1
            if low[v] >= disc[p]:
                if p != root:
                    is_ap[p] = True
                while True:
                    e = estack.pop(); block_of[e] = nblocks
                    if e == k: break
                nblocks += 1
        if root_children >= 2:
            is_ap[root] = True
        while vstack:
            becc_of[vstack.pop()] = nbecc
        nbecc += 1
        if not push_loops:
            assert not estack
        estack.clear()
    # canonical relabelling: blocks by first position, 2ecc by first vertex
    relabel, bcc = {}, []
    for k in range(len(es)):
        b = block_of[k]
        if b < 0:
            continue
        if b not in relabel:
            relabel[b] = len(bcc); bcc.append([])
        bcc[relabel[b]].append(k)
    rl, becc = {}, []
    for i, v in enumerate(vs):
        c = becc_of[i]
        if c not in rl:
            rl[c] = len(becc); becc.append([])
        becc[rl[c]].append(v)
    cc, _ = components(vs, es)
    return finish(vs, es, cc, [k for k in range(len(es)) if is_bridge[k]],
                  [v for i, v in enumerate(vs) if is_ap[i]], bcc, becc)


# ------------------------------- NetworkX cross-check ----------------------------------------

def networkx_check(vs, es, got):
    M = nx.MultiGraph()
    M.add_nodes_from(vs)
    M.add_edges_from(es)
    G = nx.Graph(M)
    fs = lambda groups: {frozenset(g) for g in groups}
    assert fs(nx.connected_components(M)) == fs(got["cc"]), "nx cc"
    pair = lambda k: frozenset(es[k])
    assert {frozenset(e) for e in nx.bridges(M)} == {pair(k) for k in got["br"]}, "nx bridges"
    assert nx.has_bridges(M) == got["hasbr"]
    assert set(nx.articulation_points(G)) == set(got["ap"]), "nx ap"
    # blocks: the partition of the distinct non-loop pairs
    nxb = {frozenset(frozenset(e) for e in c if e[0] != e[1]) for c in nx.biconnected_component_edges(G)}
    nxb.discard(frozenset())
    ours = {frozenset(pair(k) for k in b) for b in got["bcc"]}
    assert nxb == ours, ("nx blocks", nxb, ours)
    assert fs(nx.biconnected_components(G)) == fs(got["bccv"]), "nx block vertices"
    H = M.copy()
    H.remove_edges_from([es[k] for k in got["br"]])  # each bridge is a single edge between its ends
    assert fs(nx.connected_components(H)) == fs(got["becc"]), "nx 2ecc"
    if not M.is_multigraph() or all(len(M[u][v]) == 1 for u, v in G.edges()):
        if not any(u == v for u, v in es):
            assert fs(nx.algorithms.connectivity.bridge_components(G)) == fs(got["becc"])
    assert (nx.is_biconnected(G) if len(vs) else False) == got["bic"], "nx bic"
    conn = nx.is_connected(M) if len(vs) else False
    assert conn == got["conn"], "nx conn"
    if len(vs) >= 2 and conn and not M.is_multigraph() is False:
        pass
    if len(vs) >= 2 and not any(len(M[u][v]) > 1 for u, v in G.edges() if u != v):
        Gs = nx.Graph(G); Gs.remove_edges_from(nx.selfloop_edges(Gs))
        assert nx.is_k_edge_connected(Gs, 2) == got["bec"], "nx bec"


# ------------------------------- catalog parsing ---------------------------------------------

def parse_value(s):
    s = s.strip()
    if s in ("T", "F"):
        return s == "T"
    if re.fullmatch(r"\d+", s):
        return int(s)
    # nested lists of atoms
    s2 = re.sub(r"([A-Za-z_][A-Za-z0-9_]*)", r'"\1"', s)
    return eval(s2)


def parse_expected(s):
    out = {}
    for m in re.finditer(r"(\w+)=(\[[^\s]*\]|\S+)", s):
        out[m.group(1)] = parse_value(m.group(2))
    return out


def catalog():
    rows = []
    for line in (HERE / "cases.md").read_text().splitlines():
        m = re.match(r"\|\s*(CN-\d+[a-z]?)\s*\|", line)
        if not m:
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 4:
            continue
        g = re.search(r"`([^`]*)`", cells[2])
        e = re.search(r"`([^`]*)`", cells[3])
        if not g or not e:
            rows.append((m.group(1), None, None))
            continue
        rows.append((m.group(1), g.group(1), parse_expected(e.group(1))))
    return rows


def compute(vs, es):
    small = len(es) <= 400 and len(vs) <= 400
    ht = hopcroft_tarjan(vs, es)
    if small:
        bf = brute(vs, es)
        assert bf == ht, ("brute force and Hopcroft–Tarjan disagree", bf, ht)
    if len(es) <= 20000:
        networkx_check(vs, es, ht)
    return ht


def laws(vs, es, r):
    """Laws every result satisfies (cases CN-290 …)."""
    cc = r["cc"]
    loops = [k for k, (u, v) in enumerate(es) if u == v]
    # blocks partition the non-loop edges
    flat = sorted(k for b in r["bcc"] for k in b)
    assert flat == [k for k in range(len(es)) if k not in set(loops)]
    # a bridge is exactly a one-edge block
    assert sorted(b[0] for b in r["bcc"] if len(b) == 1) == r["br"]
    # articulation points are the vertices in two or more blocks
    count = {v: 0 for v in vs}
    for b in r["bccv"]:
        for x in b: count[x] += 1
    assert [v for v in vs if count[v] >= 2] == r["ap"]
    # sum over blocks of (|V(B)| - 1) = n - c
    assert sum(len(b) - 1 for b in r["bccv"]) == len(vs) - len(cc)
    # 2ecc count = components + bridges
    assert r["nbecc"] == len(cc) + len(r["br"])
    # every 2ecc lies inside one component; every block's vertices in one 2ecc unless it is a bridge
    # block-cut tree: a forest with one tree per component that has a non-loop edge
    nb, nap = len(r["bcc"]), len(r["ap"])
    tree_edges = sum(len(x) for x in r["bct"])
    with_edges = sum(1 for c in cc if any(u != v and u in set(c) for u, v in es))
    assert nb + nap - tree_edges == with_edges, "block-cut forest"
    if len(es) <= 400:
        # CN-355: a vertex with a non-loop edge is in c(G - v) - c(G) + 1 blocks
        for v in vs:
            if any(u != w and v in (u, w) for u, w in es):
                cv = len(components(vs, es, drop_vertex=v)[0])
                assert count[v] == cv - len(cc) + 1, "CN-355"
        # CN-365: a block on >= 3 vertices is biconnected on its own; on 2 vertices it is one
        # edge or a bundle of parallel edges
        for b, bv in zip(r["bcc"], r["bccv"]):
            sub = hopcroft_tarjan(bv, [es[k] for k in b])
            assert sub["bic"] and sub["nbcc"] == 1
        # CN-368: each 2-edge-connected component's induced subgraph has no bridge
        for comp in r["becc"]:
            cs = set(comp)
            sub = hopcroft_tarjan(comp, [e for e in es if e[0] in cs and e[1] in cs])
            assert sub["br"] == [] and sub["ncc"] == 1
        # CN-369
        if r["bec"]:
            assert r["conn"]
        k2 = any(len(c) == 2 and sum(1 for u, w in es if {u, w} == set(c)) == 1 for c in cc)
        if r["bic"] and not k2:
            assert r["bec"]
    return True


# ------------------------------- random and stress sections ----------------------------------

def random_multigraph(rng, n, m, loops=True, parallel=True):
    es = []
    while len(es) < m:
        u, v = rng.randrange(n), rng.randrange(n)
        if u == v and not loops:
            continue
        if not parallel and (frozenset((u, v)) in {frozenset(e) for e in es}):
            continue
        es.append((u, v))
    return make_graph(range(n), es)


def random_section(trials=1500):
    rng = random.Random(20261008)
    for t in range(trials):
        n = rng.randint(1, 10)
        m = rng.randint(0, 16)
        vs, es = random_multigraph(rng, n, m)
        r = compute(vs, es)
        laws(vs, es, r)
        # invariances: doubling every edge removes all bridges, keeps articulation points
        d = hopcroft_tarjan(vs, es + es)
        assert d["br"] == [] and d["ap"] == r["ap"] and d["becc"] == r["cc"]
        assert [sorted(b) for b in d["bccv"]] == [sorted(b) for b in r["bccv"]]
        # adding a self-loop at the end changes nothing but the edge count
        if vs:
            l = hopcroft_tarjan(vs, es + [(vs[0], vs[0])])
            assert l["ap"] == r["ap"] and l["br"] == r["br"] and l["bcc"] == r["bcc"]
        # permuting vertices keeps the sets
        perm = list(vs); rng.shuffle(perm)
        p = hopcroft_tarjan(*make_graph(perm, es))
        assert set(p["ap"]) == set(r["ap"]) and p["br"] == r["br"] and p["bcc"] == r["bcc"]
    for t in range(400):
        n = rng.randint(8, 30)
        vs, es = random_multigraph(rng, n, rng.randint(n - 3, 2 * n), loops=rng.random() < 0.5,
                                   parallel=rng.random() < 0.5)
        laws(vs, es, compute(vs, es))
    # Boost's biconnected_components_test: G(100, 500) with parallel edges, articulation points
    # against vertex removal (here also everything else, and sparser cuts so there is something to find)
    for n, m in [(100, 500), (100, 100), (100, 120), (300, 320)]:
        vs, es = random_multigraph(rng, n, m, loops=False)
        r = compute(vs, es)
        laws(vs, es, r)
    print(f"random: {trials} small multigraphs with loops and 400 on 8-30 vertices, brute force = Hopcroft–Tarjan = NetworkX, laws hold")


def planted_section(rows):
    """The two classic mistakes, and the catalog rows that catch them."""
    by_id = {cid: (spec, exp) for cid, spec, exp in rows if spec}
    caught = {}
    for name, kw in [("skip the parent vertex", dict(skip_parent_vertex=True)),
                     ("push self-loops onto the edge stack", dict(push_loops=True))]:
        caught[name] = []
        for cid, (spec, exp) in by_id.items():
            vs, es = parse_graph(spec)
            if len(es) > 5000:
                continue
            r = hopcroft_tarjan(vs, es, **kw)
            if any(r[k] != v for k, v in exp.items()):
                caught[name].append(cid)
        assert caught[name], name
        print(f"planted: '{name}' fails {len(caught[name])} rows: {', '.join(caught[name])}")


def stress_section():
    n = 100_000
    vs, es = make_graph([], [(i, i + 1) for i in range(n - 1)])
    r = hopcroft_tarjan(vs, es)
    assert r["nbr"] == n - 1 and r["nap"] == n - 2 and r["nbcc"] == n - 1 and r["nbecc"] == n
    vs, es = make_graph([], [(i, (i + 1) % n) for i in range(n)])
    r = hopcroft_tarjan(vs, es)
    assert r["nbr"] == 0 and r["nap"] == 0 and r["nbcc"] == 1 and r["bic"] and r["bec"]
    print("stress: 10^5 path and cycle, iterative, as the catalog states")


# ------------------------------- main --------------------------------------------------------

def main():
    check_fixture_transcription()
    emit = sys.argv[sys.argv.index("--emit") + 1] if "--emit" in sys.argv else None
    quick = "--quick" in sys.argv
    rows = catalog()
    checked = skipped = 0
    for cid, spec, exp in rows:
        if emit and cid != emit:
            continue
        if spec is None:
            skipped += 1
            continue
        vs, es = parse_graph(spec)
        r = compute(vs, es)
        laws(vs, es, r)
        if emit:
            print(cid, len(vs), "vertices", len(es), "edges")
            for k, v in r.items():
                s = str(v).replace(" ", "").replace("'", "")
                print(f"  {k}={'T' if v is True else 'F' if v is False else s}")
        for k, v in exp.items():
            if k not in r:
                raise SystemExit(f"{cid}: unknown key {k}")
            if r[k] != v:
                raise SystemExit(f"{cid}: {k} expected {v}, reference computes {r[k]}")
            checked += 1
    if emit:
        return
    print(f"catalog: {len(rows) - skipped} graph cases, {checked} values agree with brute force, "
          f"Hopcroft–Tarjan and NetworkX ({skipped} rows are laws or conformance, checked below or not graph data)")
    if not quick:
        random_section()
        planted_section(rows)
        stress_section()
    print("ok")


if __name__ == "__main__":
    main()
