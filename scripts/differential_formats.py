"""The GraphFormats section of scripts/differential.py.

Each random case (the harness's generator: a simple graph on 0..<n, loops allowed, integer
weights) becomes a graph per format, with awkward vertex names and typed attributes where the
format carries them, and parallel edges where it holds them. The library (Differential's
`formats` mode) writes each graph and reads the reference's text; the checks:

- GML, Pajek, Cytoscape JSON, the edge list (with a delimiter, and with NetworkX's dict data):
  the library's text read by NetworkX 3.7 is the graph, and NetworkX's text read by the library is
  the graph; GML, Pajek and Cytoscape JSON also byte for byte against NetworkX's writer
  (`generate_gml`, `generate_pajek`, `json.dumps(cytoscape_data(G))`), with edges compared as a
  multiset (NetworkX lists them by adjacency, and an undirected one from either end).
- graph6: byte for byte against `to_graph6_bytes`, and NetworkX's bytes read back.
- sparse6 (loops, parallel edges): byte for byte against an encoder written here from nauty's
  formats.txt (NetworkX pads differently in a few cases, and uses 1 bit per number for n <= 1);
  NetworkX's decoder on the library's text (n >= 2) and the library on NetworkX's text.
- digraph6, DIMACS (sp and edge), METIS: byte for byte against writers written here from the
  formats' definitions, and their text (with comments added) read back by the library; a parser
  here also reads the library's text.
- Node-link JSON with tuple nodes: NetworkX's text read by the library names each node by the
  tuple's canonical JSON text.

Answers that NetworkX gets wrong are not compared (KNOWN below).
"""

import json
import math
import struct
import subprocess
from collections import Counter

import networkx as nx

COVERED = Counter()

# NetworkX behaviors the comparisons work around, each with the reason.
KNOWN = {
    "sparse6 padding": "NetworkX pads with a 0 bit whenever the current vertex is below n - 1; nauty only when it is n - 2",
    "sparse6 small n": "NetworkX gives a vertex number 1 bit for n <= 1; nauty 0 bits",
    "pajek apostrophe": "NetworkX's writer leaves a label holding ' unquoted, which its own shlex reader cannot read back",
    "cytoscape multigraph flag": "NetworkX writes multigraph true for any MultiGraph; the library when a pair has two edges",
}

NAMES = ["v", "é", "a b", 'q"x', "amp&", "日本", "x\\y", "lt<", "tab\tx", "nbsp\u00a0", "🎈", "apo'"]


def name_pool(rng, n, forbidden=""):
    """n distinct awkward names avoiding the characters in `forbidden`."""
    pool = [s for s in NAMES if not any(c in s for c in forbidden)]
    return [f"{rng.choice(pool)}{i}" for i in range(n)]


def enc(key, x):
    if type(x) is bool:
        return [key, "b", "true" if x else "false"]
    if type(x) is int:
        return [key, "i", str(x)]
    if type(x) is float:
        return [key, "d", str(struct.unpack("<Q", struct.pack("<d", x))[0])]
    return [key, "s", x]


def dec(t):
    k, kind, v = t
    if kind == "b":
        return k, v == "true"
    if kind == "i":
        return k, int(v)
    if kind == "d":
        return k, struct.unpack("<d", struct.pack("<Q", int(v)))[0]
    return k, v


def nv(x):
    """A value as compared: typed, NaN equal to NaN."""
    if type(x) is float:
        return ("f", repr(x))
    return (type(x).__name__, x)


class G:
    """A graph as the comparisons see it: names, edges [u, v] by number, ordered attributes."""

    def __init__(self, directed, vertices, edges, vattrs=None, eattrs=None, gattrs=None):
        self.directed = directed
        self.vertices = list(vertices)
        self.edges = [list(e) for e in edges]
        self.vattrs = vattrs if vattrs is not None else [{} for _ in self.vertices]
        self.eattrs = eattrs if eattrs is not None else [{} for _ in self.edges]
        self.gattrs = gattrs if gattrs is not None else {}

    def wire(self):
        return {"directed": self.directed, "vertices": [str(v) for v in self.vertices], "edges": self.edges,
                "vertexAttributes": [[enc(k, x) for k, x in a.items()] for a in self.vattrs],
                "edgeAttributes": [[enc(k, x) for k, x in a.items()] for a in self.eattrs],
                "graphAttributes": [enc(k, x) for k, x in self.gattrs.items()]}

    @staticmethod
    def unwire(w):
        return G(w["directed"], w["vertices"], w["edges"],
                 [dict(dec(t) for t in a) for a in w["vertexAttributes"]],
                 [dict(dec(t) for t in a) for a in w["edgeAttributes"]],
                 dict(dec(t) for t in w["graphAttributes"]))

    def canon(self, vertices=True, vattrs=True, gattrs=True):
        """(vertices in order with attributes, edge multiset with attributes, graph attributes)."""
        def ends(u, v):
            a, b = self.vertices[u], self.vertices[v]
            return (a, b) if self.directed or repr(a) <= repr(b) else (b, a)
        edges = Counter((ends(u, v), frozenset((k, nv(x)) for k, x in a.items())) for (u, v), a in zip(self.edges, self.eattrs))
        vs = [(v, tuple((k, nv(x)) for k, x in sorted(a.items())) if vattrs else ()) for v, a in zip(self.vertices, self.vattrs)]
        return (vs if vertices else None, edges, tuple(sorted((k, nv(x)) for k, x in self.gattrs.items())) if gattrs else ())


def from_nx(H, drop_v=(), drop_e=(), drop_g=()):
    """A NetworkX graph as a G (attributes in `drop_*` left out)."""
    vertices = list(H.nodes)
    index = {v: i for i, v in enumerate(vertices)}
    edges, eattrs = [], []
    data = H.edges(keys=True, data=True) if H.is_multigraph() else H.edges(data=True)
    for e in data:
        u, v, a = e[0], e[1], e[-1]
        edges.append([index[u], index[v]])
        eattrs.append({k: x for k, x in a.items() if k not in drop_e})
    vattrs = [{k: x for k, x in H.nodes[v].items() if k not in drop_v} for v in vertices]
    gattrs = {k: x for k, x in H.graph.items() if k not in drop_g}
    return G(H.is_directed(), vertices, edges, vattrs, eattrs, gattrs)


def to_nx(g, multi):
    H = (nx.MultiDiGraph() if g.directed else nx.MultiGraph()) if multi else (nx.DiGraph() if g.directed else nx.Graph())
    H.graph.update(g.gattrs)
    for v, a in zip(g.vertices, g.vattrs):
        H.add_node(v, **a)
    for (u, v), a in zip(g.edges, g.eattrs):
        H.add_edge(g.vertices[u], g.vertices[v], **a)
    return H


def has_parallel(g):
    seen = set()
    for u, v in g.edges:
        k = (u, v) if g.directed else (min(u, v), max(u, v))
        if k in seen:
            return True
        seen.add(k)
    return False


def with_parallels(rng, case, simple=False, loops=True):
    """The case's edges [u, v, w], loops dropped unless `loops`, some repeated unless `simple`."""
    edges = [e for e in case["edges"] if loops or e[0] != e[1]]
    if not simple and edges and rng.random() < 0.4:
        for _ in range(rng.randint(1, 4)):
            u, v, w = rng.choice(edges)
            edges.append([v, u, w] if not case["directed"] and rng.random() < 0.5 else [u, v, w])
    return edges


def number(rng):
    return rng.choice([rng.randint(-5, 5), rng.randint(-10**6, 10**6), rng.random() * 100, -0.5, 1e-7, 1e20, 2.0])


# ------------------------------------------------------------------------------------- encoders

def nauty_n(n):
    if n <= 62:
        return bytes([63 + n])
    if n <= 258047:
        return bytes([126] + [63 + (n >> s & 63) for s in (12, 6, 0)])
    return bytes([126, 126] + [63 + (n >> s & 63) for s in (30, 24, 18, 12, 6, 0)])


def pack6(bits):
    bits = bits + [0] * (-len(bits) % 6)
    return bytes(63 + sum(b << (5 - s) for s, b in enumerate(bits[q:q + 6])) for q in range(0, len(bits), 6))


def digraph6(n, arcs, header):
    adj = set(arcs)
    bits = [1 if (i, j) in adj else 0 for i in range(n) for j in range(n)]
    return ((b">>digraph6<<" if header else b"") + b"&" + nauty_n(n) + pack6(bits) + b"\n").decode()


def sparse6(n, edges, header):
    """nauty's ntos6, from formats.txt: units (b, x) with k = bits of n - 1."""
    k = max(n - 1, 0).bit_length()

    def enc_k(x):
        return [(x >> (k - 1 - s)) & 1 for s in range(k)]
    bits, last = [], 0
    for j, i in sorted((max(u, v), min(u, v)) for u, v in edges):
        if j == last:
            bits += [0]
        else:
            bits += [1]
            if j > last + 1:
                bits += enc_k(j) + [0]
            last = j
        bits += enc_k(i)
    pad = -len(bits) % 6
    if pad and pad >= k + 1 and last == n - 2 and n == 1 << k:
        bits += [0] + [1] * (pad - 1)
    else:
        bits += [1] * pad
    return ((b">>sparse6<<" if header else b"") + b":" + nauty_n(n) + bytes(63 + sum(b << (5 - s) for s, b in enumerate(bits[q:q + 6]))
                                                                      for q in range(0, len(bits), 6)) + b"\n").decode()


def dimacs(g, weights):
    n = len(g.vertices)
    if g.directed:
        return f"p sp {n} {len(g.edges)}\n" + "".join(f"a {u + 1} {v + 1} {w}\n" for (u, v), w in zip(g.edges, weights))
    return f"p edge {n} {len(g.edges)}\n" + "".join(f"e {u + 1} {v + 1}\n" for u, v in g.edges)


def parse_dimacs(text, directed):
    n, edges, weights = None, [], []
    for line in text.split("\n"):
        f = line.split()
        if not f or f[0] == "c":
            continue
        if f[0] == "p":
            n = int(f[2])
        elif f[0] in "ae":
            edges.append([int(f[1]) - 1, int(f[2]) - 1])
            weights.append(int(f[3]) if directed else None)
    return n, edges, weights


def metis(g, weights):
    n = len(g.vertices)
    rows = [[] for _ in range(n)]
    for p, (u, v) in enumerate(g.edges):
        rows[u].append((v, p))
        rows[v].append((u, p))
    head = f"{n} {len(g.edges)}" + (" 1" if weights is not None else "") + "\n"
    return head + "".join(" ".join(f"{x + 1}" + (f" {weights[p]}" if weights is not None else "") for x, p in row) + "\n" for row in rows)


def parse_metis(text, weighted):
    lines = [s for s in text.split("\n") if not s.startswith("%")]
    head = lines[0].split()
    n = int(head[0])
    pairs = Counter()
    for u in range(n):
        f = list(map(int, lines[1 + u].split()))
        step = 2 if weighted else 1
        for q in range(0, len(f), step):
            v = f[q] - 1
            pairs[(min(u, v), max(u, v), f[q + 1] if weighted else None)] += 1
    return n, pairs


# ------------------------------------------------------------------------------------- formats

def gml_blocks(text, directed):
    """The GML text as (header lines, node blocks, edge-block multiset): `key` lines out, an
    undirected edge's ends in order."""
    lines = text.split("\n")
    head, nodes, edges, block = [], [], Counter(), None
    for line in lines:
        if line in ("  node [", "  edge ["):
            block = [line]
        elif block is not None:
            if line == "  ]":
                if block[0] == "  node [":
                    nodes.append(tuple(block))
                else:
                    s, t = int(block[1].split()[1]), int(block[2].split()[1])
                    if not directed and s > t:
                        s, t = t, s
                    rest = tuple(sorted(x for x in block[3:] if not x.startswith("    key ")))
                    edges[(s, t, rest)] += 1
                block = None
            else:
                block.append(line)
        else:
            head.append(line)
    return head, nodes, edges


def pajek_blocks(text, directed):
    lines = text.rstrip("\n").split("\n")
    k = lines.index("*arcs" if directed else "*edges")
    edges = Counter()
    for line in lines[k + 1:]:
        f = line.split(" ", 2)
        u, v = int(f[0]), int(f[1])
        if not directed and u > v:
            u, v = v, u
        edges[(u, v, f[2])] += 1
    return lines[:k + 1], edges


def cytoscape_normal(text, directed):
    d = json.loads(text)
    edges = Counter()
    for e in d["elements"]["edges"]:
        data = dict(e["data"])
        if not directed and data["source"] > data["target"]:
            data["source"], data["target"] = data["target"], data["source"]
        data.pop("key", None)
        edges[json.dumps(data, sort_keys=True)] += 1
    d["elements"]["edges"] = edges
    return d


def build_requests(rng, case):
    """[(request, check)]: each check takes the library's answer and returns problems."""
    out = []
    n, directed = case["n"], case["directed"]
    tag = f"{'directed' if directed else 'undirected'} n={n}"

    def add(request, check, name):
        request.setdefault("directed", directed)
        out.append((request, check, name))

    # GML.
    names = name_pool(rng, n)
    edges = with_parallels(rng, case)
    vattrs = [{"score": number(rng), "kind": rng.choice(NAMES)} if rng.random() < 0.5 else {} for _ in range(n)]
    if n and rng.random() < 0.2:
        vattrs[0]["big"] = 5_000_000_000
    if n and rng.random() < 0.2:
        vattrs[0]["odd"] = rng.choice([math.inf, -math.inf, math.nan])
    eattrs = [{"weight": w} for _, _, w in edges]
    g = G(directed, names, [e[:2] for e in edges], vattrs, eattrs, {"name": rng.choice(NAMES)})
    multi = has_parallel(g)
    H = to_nx(g, multi)
    nx_text = "\n".join(nx.generate_gml(H)) + "\n"

    def gml_write(ans, g=g, names=names, vattrs=vattrs, eattrs=eattrs, nx_text=nx_text):
        text = ans.get("text")
        if text is None:
            return [f"GML write failed: {ans.get('error')}"]
        problems = []
        theirs = from_nx(nx.parse_gml(text), drop_e={"key"})
        expected = G(directed, names, g.edges, [{k: (str(x) if k == "big" else x) for k, x in a.items()} for a in vattrs], eattrs, g.gattrs)
        if theirs.canon() != expected.canon():
            problems.append("GML: NetworkX reads the library's text as another graph")
        if gml_blocks(text, directed) != gml_blocks(nx_text, directed):
            problems.append(f"GML: the library's text differs from generate_gml's:\n{text[:400]}\n---\n{nx_text[:400]}")
        COVERED["GML written"] += 1
        return problems
    add({"op": "write", "format": "gml", "graph": g.wire()}, gml_write, "gml write")

    def gml_read(ans, H=H, multi=multi):
        if ans.get("graph") is None:
            return [f"GML: the library cannot read generate_gml's text: {ans.get('error')}"]
        mine = G.unwire(ans["graph"])
        theirs = from_nx(H)
        if multi:
            # The library reports `key` as an edge attribute.
            theirs = from_nx(H)
            for (_, _, k), a in zip(H.edges(keys=True), theirs.eattrs):
                a["key"] = k
        expected = G(directed, theirs.vertices, theirs.edges, [{k: (str(x) if k == "big" else x) for k, x in a.items()} for a in theirs.vattrs],
                     theirs.eattrs, theirs.gattrs)
        COVERED["GML read"] += 1
        return [] if mine.canon() == expected.canon() else ["GML: the library reads generate_gml's text as another graph"]
    add({"op": "read", "format": "gml", "text": nx_text}, gml_read, "gml read")

    # Pajek (NetworkX: string extras only, no apostrophe in labels it writes).
    names = name_pool(rng, n, forbidden="'\t")
    edges = with_parallels(rng, case)
    vattrs = []
    for _ in range(n):
        a = {}
        if rng.random() < 0.5:
            a["x"], a["y"] = number(rng), number(rng)
        if rng.random() < 0.3:
            a["shape"] = rng.choice(["box", "ellipse", "a b"])
        if rng.random() < 0.3:
            a["color"] = rng.choice(["red", "dark blue", 'q"'])
        vattrs.append(a)
    eattrs = [({"weight": float(w)} if rng.random() < 0.7 else {}) | ({"kind": "x y"} if rng.random() < 0.3 else {}) for _, _, w in edges]
    g = G(directed, names, [e[:2] for e in edges], vattrs, eattrs)
    H = to_nx(g, True)
    nx_text = "\n".join(nx.generate_pajek(H)) + "\n"

    def pajek_expected(names=names, vattrs=vattrs, eattrs=eattrs, g=g):
        va = []
        for a in vattrs:
            b = {"x": float(a.get("x", 0.0)), "y": float(a.get("y", 0.0)), "shape": a.get("shape", "ellipse")}
            if "color" in a:
                b["color"] = a["color"]
            va.append(b)
        ea = [{"weight": a.get("weight", 1.0)} | ({"kind": a["kind"]} if "kind" in a else {}) for a in eattrs]
        return G(directed, names, g.edges, va, ea)

    def pajek_write(ans, nx_text=nx_text, pajek_expected=pajek_expected):
        text = ans.get("text")
        if text is None:
            return [f"Pajek write failed: {ans.get('error')}"]
        problems = []
        theirs = from_nx(nx.parse_pajek(text), drop_v={"id"})
        if theirs.canon() != pajek_expected().canon():
            problems.append("Pajek: NetworkX reads the library's text as another graph")
        if pajek_blocks(text, directed) != pajek_blocks(nx_text, directed):
            problems.append(f"Pajek: the library's text differs from generate_pajek's:\n{text[:400]}\n---\n{nx_text[:400]}")
        COVERED["Pajek written"] += 1
        return problems
    add({"op": "write", "format": "pajek", "graph": g.wire()}, pajek_write, "pajek write")

    def pajek_read(ans, pajek_expected=pajek_expected):
        if ans.get("graph") is None:
            return [f"Pajek: the library cannot read generate_pajek's text: {ans.get('error')}"]
        COVERED["Pajek read"] += 1
        return [] if G.unwire(ans["graph"]).canon() == pajek_expected().canon() else ["Pajek: the library reads generate_pajek's text as another graph"]
    add({"op": "read", "format": "pajek", "text": nx_text}, pajek_read, "pajek read")

    # graph6 (simple, undirected, no loops) and sparse6 (loops, parallel edges); digraph6.
    if not directed:
        pairs = sorted({(min(u, v), max(u, v)) for u, v, _ in case["edges"] if u != v})
        S = nx.Graph()
        S.add_nodes_from(range(n))
        S.add_edges_from(pairs)
        header = rng.random() < 0.3
        g6 = nx.to_graph6_bytes(S, header=header).decode()
        g = G(False, list(range(n)), [list(p) for p in rng.sample(pairs, len(pairs))])

        def graph6_write(ans, g6=g6):
            COVERED["graph6 written"] += 1
            return [] if ans.get("text") == g6 else [f"graph6: library {ans.get('text') or ans.get('error')!r}, NetworkX {g6!r}"]
        add({"op": "write", "format": "graph6", "graph": g.wire(), "header": header}, graph6_write, "graph6 write")

        def graph6_read(ans, pairs=pairs):
            if ans.get("graph") is None:
                return [f"graph6: the library cannot read to_graph6_bytes's text: {ans.get('error')}"]
            mine = G.unwire(ans["graph"])
            COVERED["graph6 read"] += 1
            ok = mine.vertices == [str(i) for i in range(n)] and sorted(tuple(sorted(e)) for e in mine.edges) == pairs
            return [] if ok else ["graph6: the library reads to_graph6_bytes's text as another graph"]
        add({"op": "read", "format": "graph6", "text": g6}, graph6_read, "graph6 read")

        multi_edges = [e[:2] for e in with_parallels(rng, case)]
        header = rng.random() < 0.3
        mine6 = sparse6(n, multi_edges, header)
        expected_multiset = Counter((min(u, v), max(u, v)) for u, v in multi_edges)
        g = G(False, list(range(n)), multi_edges)

        def sparse6_write(ans, mine6=mine6, expected_multiset=expected_multiset):
            text = ans.get("text")
            if text != mine6:
                return [f"sparse6: library {text or ans.get('error')!r}, nauty's encoding {mine6!r}"]
            COVERED["sparse6 written"] += 1
            if n >= 2:
                H6 = nx.from_sparse6_bytes(text.rstrip("\n").encode())
                if Counter((min(u, v), max(u, v)) for u, v in H6.edges()) != expected_multiset or H6.number_of_nodes() != n:
                    return ["sparse6: NetworkX decodes the library's text as another graph"]
                COVERED["sparse6 decoded by NetworkX"] += 1
            return []
        add({"op": "write", "format": "sparse6", "graph": g.wire(), "header": header}, sparse6_write, "sparse6 write")
        if n >= 2:
            M = nx.MultiGraph()
            M.add_nodes_from(range(n))
            M.add_edges_from(multi_edges)
            nx6 = nx.to_sparse6_bytes(M, header=False).decode()
            if nx6 != sparse6(n, multi_edges, False):
                COVERED["sparse6: NetworkX pads differently"] += 1

            def sparse6_read(ans, expected_multiset=expected_multiset):
                if ans.get("graph") is None:
                    return [f"sparse6: the library cannot read to_sparse6_bytes's text: {ans.get('error')}"]
                mine = G.unwire(ans["graph"])
                COVERED["sparse6 read"] += 1
                ok = len(mine.vertices) == n and Counter(tuple(sorted(e)) for e in mine.edges) == expected_multiset
                return [] if ok else ["sparse6: the library reads to_sparse6_bytes's text as another graph"]
            add({"op": "read", "format": "sparse6", "text": nx6}, sparse6_read, "sparse6 read")
    else:
        arcs = [tuple(e[:2]) for e in case["edges"]]
        header = rng.random() < 0.3
        d6 = digraph6(n, arcs, header)
        g = G(True, list(range(n)), [list(a) for a in arcs])

        def digraph6_write(ans, d6=d6):
            COVERED["digraph6 written"] += 1
            return [] if ans.get("text") == d6 else [f"digraph6: library {ans.get('text') or ans.get('error')!r}, encoder {d6!r}"]
        add({"op": "write", "format": "digraph6", "graph": g.wire(), "header": header}, digraph6_write, "digraph6 write")

        def digraph6_read(ans, arcs=arcs):
            if ans.get("graph") is None:
                return [f"digraph6: the library cannot read the encoder's text: {ans.get('error')}"]
            mine = G.unwire(ans["graph"])
            COVERED["digraph6 read"] += 1
            return [] if sorted(map(tuple, mine.edges)) == sorted(arcs) and len(mine.vertices) == n else ["digraph6: another graph"]
        add({"op": "read", "format": "digraph6", "text": d6}, digraph6_read, "digraph6 read")

    # DIMACS.
    edges = with_parallels(rng, case)
    g = G(directed, list(range(n)), [e[:2] for e in edges], eattrs=[{"weight": w} for _, _, w in edges])
    weights = [w for _, _, w in edges]
    ref = dimacs(g, weights)

    def dimacs_write(ans, ref=ref, weights=weights, g=g):
        text = ans.get("text")
        if text != ref:
            return [f"DIMACS: library {(text or ans.get('error'))[:200]!r}, definition {ref[:200]!r}"]
        pn, pe, pw = parse_dimacs(text, directed)
        COVERED["DIMACS written"] += 1
        ok = pn == n and pe == g.edges and (pw == weights or not directed)
        return [] if ok else ["DIMACS: the parser here reads the library's text as another graph"]
    add({"op": "write", "format": "dimacs", "graph": g.wire()}, dimacs_write, "dimacs write")
    commented = "c a comment\n" + ref.replace("\n", "\nc between\n", 1)

    def dimacs_read(ans, g=g, weights=weights):
        if ans.get("graph") is None:
            return [f"DIMACS: the library cannot read the definition's text: {ans.get('error')}"]
        mine = G.unwire(ans["graph"])
        COVERED["DIMACS read"] += 1
        ok = len(mine.vertices) == n and mine.edges == g.edges and (not directed or [a["weight"] for a in mine.eattrs] == weights)
        return [] if ok else ["DIMACS: the library reads the definition's text as another graph"]
    add({"op": "read", "format": "dimacs", "text": commented}, dimacs_read, "dimacs read")

    # METIS (undirected, simple, no loops).
    if not directed:
        pairs = sorted({(min(u, v), max(u, v)) for u, v, _ in case["edges"] if u != v})
        rng.shuffle(pairs)
        weighted = rng.random() < 0.5
        weights = [rng.randint(0, 9) for _ in pairs] if weighted else None
        g = G(False, list(range(n)), [list(p) if rng.random() < 0.5 else [p[1], p[0]] for p in pairs],
              eattrs=[{"weight": w} for w in weights] if weighted else None)
        ref = metis(g, weights)

        def metis_write(ans, ref=ref, weighted=weighted, g=g, weights=weights):
            text = ans.get("text")
            if text != ref:
                return [f"METIS: library {(text or ans.get('error'))[:200]!r}, definition {ref[:200]!r}"]
            pn, pp = parse_metis(text, weighted)
            expected = Counter()
            for p, (u, v) in enumerate(g.edges):
                expected[(min(u, v), max(u, v), weights[p] if weighted else None)] += 2
            COVERED["METIS written"] += 1
            return [] if pn == n and pp == expected else ["METIS: the parser here reads the library's text as another graph"]
        add({"op": "write", "format": "metis", "graph": g.wire(), "weighted": weighted}, metis_write, "metis write")

        def metis_read(ans, g=g, weights=weights, weighted=weighted):
            if ans.get("graph") is None:
                return [f"METIS: the library cannot read the definition's text: {ans.get('error')}"]
            mine = G.unwire(ans["graph"])
            COVERED["METIS read"] += 1
            got = Counter((min(u, v), max(u, v), a.get("weight")) for (u, v), a in zip(mine.edges, mine.eattrs))
            exp = Counter((min(u, v), max(u, v), weights[p] if weighted else None) for p, (u, v) in enumerate(g.edges))
            return [] if len(mine.vertices) == n and got == exp else ["METIS: the library reads the definition's text as another graph"]
        add({"op": "read", "format": "metis", "text": "% a comment\n" + ref}, metis_read, "metis read")

    # Cytoscape JSON (finite values only: JSON has no others).
    names = name_pool(rng, n)
    edges = with_parallels(rng, case)
    vattrs = [{"score": number(rng), "flag": rng.random() < 0.5} if rng.random() < 0.5 else {} for _ in range(n)]
    eattrs = [{"weight": w} | ({"note": rng.choice(NAMES)} if rng.random() < 0.3 else {}) for _, _, w in edges]
    g = G(directed, names, [e[:2] for e in edges], vattrs, eattrs, {"title": rng.choice(NAMES), "rank": 3})
    multi = has_parallel(g)
    H = to_nx(g, multi)
    nx_text = json.dumps(nx.cytoscape_data(H))

    def cytoscape_write(ans, g=g, H=H, nx_text=nx_text, multi=multi):
        text = ans.get("text")
        if text is None:
            return [f"Cytoscape write failed: {ans.get('error')}"]
        problems = []
        theirs = from_nx(nx.cytoscape_graph(json.loads(text)), drop_v={"id", "value", "name"}, drop_e={"source", "target", "key"})
        if theirs.canon() != g.canon():
            problems.append("Cytoscape: NetworkX reads the library's text as another graph")
        cut = '"edges": ['
        if (cytoscape_normal(text, directed) != cytoscape_normal(nx_text, directed)
                or text[:text.index(cut)] != nx_text[:nx_text.index(cut)]):
            problems.append(f"Cytoscape: the library's text differs from cytoscape_data's:\n{text[:400]}\n---\n{nx_text[:400]}")
        COVERED["Cytoscape written"] += 1
        return problems
    add({"op": "write", "format": "cytoscape", "graph": g.wire()}, cytoscape_write, "cytoscape write")

    def cytoscape_read(ans, g=g):
        if ans.get("graph") is None:
            return [f"Cytoscape: the library cannot read cytoscape_data's text: {ans.get('error')}"]
        mine = G.unwire(ans["graph"])
        expected = G(directed, g.vertices, g.edges, [a | {"value": v, "name": v} for v, a in zip(g.vertices, g.vattrs)], g.eattrs, g.gattrs)
        COVERED["Cytoscape read"] += 1
        return [] if mine.canon() == expected.canon() else ["Cytoscape: the library reads cytoscape_data's text as another graph"]
    add({"op": "read", "format": "cytoscape", "text": nx_text}, cytoscape_read, "cytoscape read")

    # Edge list with a delimiter, the library writing a weight column, NetworkX writing dicts.
    delimiter = rng.choice([",", ";", "\t", "|", " "])
    forbidden = delimiter + "#" + (" \t\u00a0" if delimiter == " " else "")
    names = name_pool(rng, n, forbidden=forbidden)
    edges = with_parallels(rng, case)
    g = G(directed, names, [e[:2] for e in edges], eattrs=[{"weight": w} for _, _, w in edges])
    lib_delimiter = None if delimiter == " " else delimiter

    def edgelist_write(ans, g=g, delimiter=delimiter):
        text = ans.get("text")
        if text is None:
            return [f"edge list write failed: {ans.get('error')}"]
        H = nx.parse_edgelist(text.split("\n"), delimiter=delimiter, data=(("weight", int),),
                              create_using=nx.MultiDiGraph if directed else nx.MultiGraph)
        COVERED["edge lists written"] += 1
        theirs = from_nx(H)
        return [] if theirs.canon(vertices=False) == g.canon(vertices=False) else ["edge list: NetworkX reads the library's text as another graph"]
    add({"op": "write", "format": "edgelist", "graph": g.wire(), "delimiter": lib_delimiter, "columns": ["weight"]},
        edgelist_write, "edge list write")
    dict_attrs = []
    for _, _, w in edges:
        a = {"weight": w}
        if rng.random() < 0.3:
            a["note"] = rng.choice(["a'b", 'q"x', "é", "x,y", "#hash", "back\\slash", ""])
        if rng.random() < 0.2:
            a["score"] = rng.choice([1.5, -0.0, 1e-07, math.inf, math.nan, True, False])
        dict_attrs.append(a if rng.random() < 0.9 else {})
    gd = G(directed, names, g.edges, eattrs=dict_attrs)
    nx_text = "\n".join(nx.generate_edgelist(to_nx(gd, True), delimiter=delimiter, data=True)) + "\n"

    def edgelist_read(ans, gd=gd):
        if ans.get("graph") is None:
            return [f"edge list: the library cannot read write_edgelist's dicts: {ans.get('error')}"]
        COVERED["edge lists with dicts read"] += 1
        mine = G.unwire(ans["graph"])
        return [] if mine.canon(vertices=False) == gd.canon(vertices=False) else ["edge list: the library reads write_edgelist's dicts as another graph"]
    add({"op": "read", "format": "edgelist", "text": nx_text, "delimiter": lib_delimiter}, edgelist_read, "edge list read")

    # Node-link JSON with tuple nodes.
    def node(i):
        return rng.choice([(i, i % 3), (str(i), "é"), ((i,), i % 2), (i, (1.5, True, None))])
    nodes = []
    seen = set()
    for i in range(n):
        t = node(i)
        while t in seen:
            t = (i, len(seen))
        seen.add(t)
        nodes.append(t)
    T = nx.DiGraph() if directed else nx.Graph()
    T.add_nodes_from(nodes)
    T.add_edges_from((nodes[u], nodes[v]) for u, v, _ in case["edges"])
    nx_text = json.dumps(nx.node_link_data(T, edges="edges"))

    def canonical(t):
        return json.dumps(json.loads(json.dumps(t)))

    def nodelink_read(ans, T=T):
        if ans.get("graph") is None:
            return [f"node-link: the library cannot read tuple ids: {ans.get('error')}"]
        mine = G.unwire(ans["graph"])
        COVERED["node-link tuple ids"] += 1
        exp = G(directed, [canonical(v) for v in T.nodes], [[list(T.nodes).index(u), list(T.nodes).index(v)] for u, v in T.edges])
        return [] if mine.canon(vattrs=False, gattrs=False) == exp.canon(vattrs=False, gattrs=False) else ["node-link: the library names tuple nodes otherwise"]
    add({"op": "read", "format": "nodelink", "text": nx_text}, nodelink_read, "node-link read")
    return [(r, c, name, tag) for r, c, name in out]


def run(executable, rng, cases, generate, record, batch=100):
    """Runs `cases` random cases through every format; returns the number of failing cases."""
    failures = 0
    for start in range(0, cases, batch):
        group = [generate(rng, i) for i in range(start, min(cases, start + batch))]
        pending = [(case, build_requests(rng, case)) for case in group]
        requests = [r for _, rs in pending for r, _, _, _ in rs]
        try:
            proc = subprocess.run([executable, "formats"], input=json.dumps(requests), capture_output=True, text=True, timeout=300)
            answers = json.loads(proc.stdout) if proc.returncode == 0 else None
        except subprocess.TimeoutExpired:
            answers = None
        if answers is None:
            # Find the cases one at a time.
            for case, rs in pending:
                one = subprocess.run([executable, "formats"], input=json.dumps([r for r, _, _, _ in rs]),
                                     capture_output=True, text=True, timeout=60)
                if one.returncode != 0:
                    failures += 1
                    record(case, [f"formats: the library crashed: {one.stderr.strip()[-500:]}"])
            continue
        k = 0
        for case, rs in pending:
            problems = []
            for _, check, name, tag in rs:
                try:
                    problems += [f"{p} ({tag})" for p in check(answers[k])]
                except Exception as error:  # A reference that cannot read the text is a problem too.
                    problems.append(f"{name}: the reference failed: {type(error).__name__}: {error} ({tag})")
                k += 1
            if problems:
                failures += 1
                record(case, problems)
    return failures
