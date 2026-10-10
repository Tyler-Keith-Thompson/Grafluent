"""Independent reference for the CommunityDetection module (catalog cases.md, CD-...).

Run:  uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 ref.py
      ... python3 ref.py --fill    rewrite '?' Expected cells of cases.md with computed values

Every Expected cell is recomputed by the model of api.md written here in index space (vertex
numbers in `vertices` order, edge numbers in position order, rows in `incidentEdges` /
`outEdges` order with an undirected self-loop twice), and checked independently:

* modularity against the matrix definition Q = 1/(2m) sum_ij (A_ij - g k_i k_j / 2m) d(c_i, c_j)
  (directed: 1/m sum_ij (A_ij - g k_i^out k_j^in / m) d) with A_ii = 2w for an undirected loop,
  and against NetworkX 3.7 `modularity` on a MultiGraph / MultiDiGraph (every case);
* coverage and performance against a pair count, and against NetworkX `partition_quality` on
  simple graphs (no loops, no parallel edges, n >= 2, m >= 1);
* Louvain: Grafluent is deterministic (vertices in index order, ties to the greatest community
  label, api.md). NetworkX 3.7 `louvain_communities` shuffles and keeps the first maximum. The
  check runs NetworkX's own `louvain_partitions` with two edits: `seed` is a random.Random whose
  shuffle is the identity, and `_one_level`'s comparison `gain > best_gain` is extended with the
  tie rule (its source is patched textually and re-executed in the module). Every Louvain case
  must equal that run;
* greedy modularity: NetworkX `greedy_modularity_communities` itself (deterministic; ties go to
  the least (u, v) pair, merging u into v), on every case with positive total weight;
* label propagation, semi-synchronous: NetworkX `label_propagation_communities` itself
  (deterministic) on simple graphs without loops; asynchronous: NetworkX `asyn_lpa_communities`
  with the identity shuffle and `choice = max` (api.md's tie rule) on graphs without loops
  (parallel edges as integer weights);
* `using:` rows: Expected must be what every order gives: the model with 200 random orders (and,
  for asynchronous label propagation, random tie choices), and NetworkX with 25 integer seeds.
"""

import inspect
import math
import random
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import networkx as nx
import networkx.algorithms.community.louvain as nx_louvain

HERE = Path(__file__).resolve().parent
CASES = HERE / "cases.md"


class Trap(Exception):
    pass


def vtok(s):
    s = s.strip()
    return int(s) if re.fullmatch(r"-?\d+", s) else s


def split_top(s, sep=","):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == sep and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return [x.strip() for x in out if x.strip()]


def items(s):
    res = []
    for t in split_top(s):
        m = re.fullmatch(r"(-?\d+)\.\.(-?\d+)", t)
        res.extend(range(int(m.group(1)), int(m.group(2)) + 1) if m else [vtok(t)])
    return res


MASK = (1 << 64) - 1


def lcg_edges(n, m, seed):
    """m pseudo-random non-loop pairs over 0..<n (api.md / cases.md `lcg`)."""
    x, out = seed & MASK, []
    def step():
        nonlocal x
        x = (x * 6364136223846793005 + 1442695040888963407) & MASK
        return (x >> 33) % n
    while len(out) < m:
        u, v = step(), step()
        if u != v:
            out.append((u, v))
    return out


def nx_named(spec):
    """`nx(name, args…)`: networkx.<name>(*args), or networkx.<name>_graph(*args)."""
    name, *args = [x.strip() for x in spec.split(",")]
    fn = getattr(nx, name) if hasattr(nx, name) and callable(getattr(nx, name)) else getattr(nx, name + "_graph")
    g = fn(*[int(a) for a in args])
    return list(g.nodes), list(g.edges())


def edge_tokens(s):
    """(listed vertices from generators, [(a, b)]) for one edge list."""
    out, extra = [], []
    for t in split_top(s):
        if t.startswith("P("):
            vs = items(t[2:-1])
            out += list(zip(vs, vs[1:]))
        elif t.startswith("C("):
            vs = items(t[2:-1])
            out += list(zip(vs, vs[1:] + vs[:1]))
        elif t.startswith("S("):
            c, rest = t[2:-1].split(";")
            out += [(vtok(c), x) for x in items(rest)]
        elif t.startswith("KB("):
            a, b = t[3:-1].split(";")
            out += [(x, y) for x in items(a) for y in items(b)]
        elif t.startswith("K("):
            vs = items(t[2:-1])
            if len(vs) == 1:
                vs = list(range(vs[0]))
            out += [(vs[i], vs[j]) for i in range(len(vs)) for j in range(i + 1, len(vs))]
        elif t.startswith("grid("):
            r, c = (int(x) for x in t[5:-1].split(","))
            extra += list(range(r * c))
            for i in range(r):
                for j in range(c):
                    v = i * c + j
                    if j + 1 < c:
                        out.append((v, v + 1))
                    if i + 1 < r:
                        out.append((v, v + c))
        elif t.startswith("kary("):
            n, k = (int(x) for x in t[5:-1].split(","))
            out += [(i, c) for i in range(n) for c in range(k * i + 1, k * i + k + 1) if c < n]
        elif t.startswith("lcg("):
            n, m, seed = (int(x) for x in t[4:-1].split(","))
            out += lcg_edges(n, m, seed)
        elif t.startswith("nx("):
            nodes, es = nx_named(t[3:-1])
            extra += nodes
            out += es
        else:
            m = re.fullmatch(r"(-?\w+)\s*(-|>)\s*(-?\w+)", t)
            assert m, f"bad edge token {t!r}"
            out.append((vtok(m.group(1)), vtok(m.group(3))))
    return extra, out


class G:
    """A graph as api.md sees it: vertices in order, edge ends by position, rows."""

    def __init__(self, directed, vertices, ends, rev=False):
        self.directed, self.vertices, self.ends = directed, vertices, ends
        self.n, self.m = len(vertices), len(ends)
        rows = [[] for _ in range(self.n)]
        for e, (a, b) in enumerate(ends):
            if directed:
                rows[a].append((b, e))
            else:
                rows[a].append((b, e))
                rows[b].append((a, e))  # a self-loop: twice in its row
        if rev:
            rows = [r[::-1] for r in rows]
        self.rows = rows

    def directed_view(self):
        """graph.directed: arc 2p forward, 2p+1 reversed; rows from incidentEdges order."""
        assert not self.directed
        ends = []
        for a, b in self.ends:
            ends += [(a, b), (b, a)]
        g = G(True, self.vertices, ends)
        rows = [[] for _ in range(self.n)]
        for v in range(self.n):
            loops = []
            for (w, e) in self.rows[v]:
                a, b = self.ends[e]
                if a == b:  # the loop's forward arc first, reversed at its second listing
                    rows[v].append((v, 2 * e + (1 if e in loops else 0)))
                    loops.append(e)
                else:
                    rows[v].append((w, 2 * e + (0 if a == v else 1)))
        g.rows = rows
        g.base_edge = lambda arc: arc // 2
        return g

    def undirected_view(self):
        assert self.directed
        return G(False, self.vertices, self.ends)


def parse_graph(cell):
    cell = cell.strip().strip("`")
    rev = False
    if cell.endswith("~rev"):
        rev, cell = True, cell[: -len("~rev")].strip()
    kind, rest = cell.split(":", 1)
    m = re.match(r"\s*\[(.*?)\]\s*(.*)", rest)
    listed, es = (m.group(1), m.group(2)) if m else ("", rest)
    extra, pairs = edge_tokens(es)
    vs, seen = [], set()
    for v in items(listed) + extra + [x for p in pairs for x in p]:
        if v not in seen:
            seen.add(v)
            vs.append(v)
    num = {v: i for i, v in enumerate(vs)}
    return G(kind.strip() == "D", vs, [(num[a], num[b]) for a, b in pairs], rev)


def parse_weights(s, m):
    s = s.strip()
    if s.startswith("["):
        out = []
        for x in split_top(s[1:-1]):
            out.append(float(x) if x in ("nan", "inf") or "." in x else int(x))
        assert len(out) == m, f"{len(out)} weights for {m} edges"
        return out
    mm = re.fullmatch(r"e%(\d+)\+(\d+)", s)
    if mm:
        k, c = int(mm.group(1)), int(mm.group(2))
        return [e % k + c for e in range(m)]
    return [float(s) if "." in s else int(s)] * m




# --------------------------------------------------------------------------------------------
# The model (api.md, index space)
# --------------------------------------------------------------------------------------------


def finite(x):
    return x == x and not math.isinf(x)


def weights_of(g, w):
    """Read every weight once in position order and check it (api.md: finite and >= 0)."""
    if w is None:
        return [1.0] * g.m
    for x in w:
        if not finite(x) or x < 0:
            raise Trap()
    return [float(x) for x in w]


def check_resolution(r):
    if not finite(r) or r < 0:
        raise Trap()


def labels_of_partition(g, comms):
    """Vertex number -> community; traps unless every vertex is listed exactly once."""
    num = {v: i for i, v in enumerate(g.vertices)}
    lab = [-1] * g.n
    for c, comm in enumerate(comms):
        for v in comm:
            if v not in num or lab[num[v]] != -1:
                raise Trap()
            lab[num[v]] = c
    if any(x == -1 for x in lab):
        raise Trap()
    return lab


def canonical(labels):
    """Communities ordered by least vertex number, each in vertex-number order (api.md)."""
    first, groups = {}, []
    for v, l in enumerate(labels):
        if l not in first:
            first[l] = len(groups)
            groups.append([])
        groups[first[l]].append(v)
    return groups


def modularity_model(g, w, labels, gamma):
    """NetworkX's arithmetic: sum over communities of L_c/m - gamma * out_c * in_c * norm."""
    m = sum(w)
    if m == 0:
        return 0.0
    k = max(labels) + 1 if labels else 0
    L, dout, din = [0.0] * k, [0.0] * k, [0.0] * k
    for e, (a, b) in enumerate(g.ends):
        if labels[a] == labels[b]:
            L[labels[a]] += w[e]
        dout[labels[a]] += w[e]
        din[labels[b]] += w[e]
        if not g.directed:
            dout[labels[b]] += w[e]
            din[labels[a]] += w[e]
    norm = 1 / m**2 if g.directed else 1 / (2 * m) ** 2
    return sum(L[c] / m - gamma * dout[c] * din[c] * norm for c in range(k))


def quality_model(g, labels):
    """(coverage, performance); NaN where the ratio is 0/0 (api.md)."""
    intra = sum(1 for a, b in g.ends if labels[a] == labels[b])
    coverage = intra / g.m if g.m else math.nan
    adj = set()
    for a, b in g.ends:
        if a != b:
            adj.add((a, b) if g.directed else (min(a, b), max(a, b)))
    good, pairs = 0, 0
    for a in range(g.n):
        for b in range(g.n):
            if a == b or (not g.directed and b < a):
                continue
            pairs += 1
            same = labels[a] == labels[b]
            good += (same and (a, b) in adj) or (not same and (a, b) not in adj)
    performance = good / pairs if pairs else math.nan
    return coverage, performance


# ---- Louvain ---------------------------------------------------------------------------------


class Level:
    """A level graph: k vertices, pair weights (undirected keys (a <= b)), loops on the diagonal."""

    def __init__(self, k, directed):
        self.k, self.directed, self.w = k, directed, {}

    def add(self, a, b, x):
        key = (a, b) if self.directed else (min(a, b), max(a, b))
        self.w[key] = self.w.get(key, 0.0) + x

    def prepare(self):
        k = self.k
        self.nbrs = [dict() for _ in range(k)]
        self.out, self.inn = [0.0] * k, [0.0] * k
        for (a, b), x in self.w.items():
            self.out[a] += x
            self.inn[b] += x
            if not self.directed:
                self.out[b] += x
                self.inn[a] += x
            if a != b:
                self.nbrs[a][b] = self.nbrs[a].get(b, 0.0) + x
                self.nbrs[b][a] = self.nbrs[b].get(a, 0.0) + x


def one_level(lv, m, resolution, order):
    lv.prepare()
    k, directed = lv.k, lv.directed
    com = list(range(k))
    if directed:
        gamma, Sin, Sout = resolution, lv.inn[:], lv.out[:]
    else:
        gamma, S = resolution / 2, lv.out[:]
    improvement, moves = False, 1
    while moves > 0:
        moves = 0
        for u in order:
            uc = com[u]
            kin = {}
            for v, x in lv.nbrs[u].items():
                kin[com[v]] = kin.get(com[v], 0.0) + x
            if directed:
                ind, outd = lv.inn[u], lv.out[u]
                Sin[uc] -= ind
                Sout[uc] -= outd
                t = outd * Sin[uc] + ind * Sout[uc]
            else:
                deg = lv.out[u]
                S[uc] -= deg
                t = S[uc] * deg
            best, bc = kin.get(uc, 0.0) * m - gamma * t, uc
            for c, x in kin.items():
                t = outd * Sin[c] + ind * Sout[c] if directed else S[c] * deg
                gain = x * m - gamma * t
                # The greatest gain; on a tie stay, else the greatest community label.
                if gain > best or (gain == best and bc != uc and c > bc):
                    best, bc = gain, c
            if directed:
                Sin[bc] += ind
                Sout[bc] += outd
            else:
                S[bc] += deg
            if bc != uc:
                com[u] = bc
                moves += 1
                improvement = True
    return com, improvement


def louvain_model(g, w, resolution=1.0, threshold=1e-7, rng=None):
    w = weights_of(g, w)
    check_resolution(resolution)
    if not finite(threshold) or threshold < 0:
        raise Trap()
    if g.m == 0:
        return list(range(g.n))
    m = sum(w)
    lv = Level(g.n, g.directed)
    for e, (a, b) in enumerate(g.ends):
        lv.add(a, b, w[e])
    node = list(range(g.n))  # vertex -> level vertex
    mod = modularity_model(g, w, list(range(g.n)), resolution)

    def order(k):
        o = list(range(k))
        if rng is not None:
            rng.shuffle(o)
        return o

    com, improvement = one_level(lv, m, resolution, order(lv.k))
    final, first = None, True
    while first or improvement:
        first = False
        rank = {c: i for i, c in enumerate(sorted(set(com)))}  # nonempty communities, label order
        labels = [rank[com[node[v]]] for v in range(g.n)]
        final = labels
        new = modularity_model(g, w, labels, resolution)
        if new - mod <= threshold:
            break
        mod = new
        nxt = Level(len(rank), g.directed)
        for (a, b), x in lv.w.items():
            nxt.add(rank[com[a]], rank[com[b]], x)
        node = labels
        lv = nxt
        com, improvement = one_level(lv, m, resolution, order(lv.k))
    return final


# ---- Greedy modularity (Clauset-Newman-Moore) ------------------------------------------------


def greedy_model(g, w, resolution=1.0):
    w = weights_of(g, w)
    check_resolution(resolution)
    n = g.n
    m = sum(w)
    if g.m == 0 or m == 0:
        return list(range(n))
    q0 = 1 / m
    out, inn = [0.0] * n, [0.0] * n
    for e, (a, b) in enumerate(g.ends):
        out[a] += w[e]
        inn[b] += w[e]
        if not g.directed:
            out[b] += w[e]
            inn[a] += w[e]
    if g.directed:
        A = [x * q0 for x in out]
        B = [x * q0 for x in inn]
    else:
        A = [x * q0 * 0.5 for x in out]
        B = A  # one array, as NetworkX's `a = b = …`
    dq = defaultdict(dict)
    for e, (a, b) in enumerate(g.ends):
        if a == b:
            continue
        dq[a][b] = dq[a].get(b, 0.0) + w[e]
        dq[b][a] = dq[b].get(a, 0.0) + w[e]
    for u in dq:
        for v in dq[u]:
            dq[u][v] = q0 * dq[u][v] - resolution * (A[u] * B[v] + B[u] * A[v])
    label = list(range(n))  # community id = surviving vertex number
    while True:
        best = None
        for u in dq:
            for v, x in dq[u].items():
                if best is None or x > best[0] or (x == best[0] and (u, v) < (best[1], best[2])):
                    best = (x, u, v)
        if best is None or best[0] < 0:
            break
        _, u, v = best
        un, vn = set(dq[u]), set(dq[v])
        for x in (un | vn) - {u, v}:
            if x in un and x in vn:
                d = dq[v][x] + dq[u][x]
            elif x in vn:
                d = dq[v][x] - resolution * (A[u] * B[x] + A[x] * B[u])
            else:
                d = dq[u][x] - resolution * (A[v] * B[x] + A[x] * B[v])
            dq[v][x] = d
            dq[x][v] = d
        for x in list(dq[u]):
            del dq[x][u]
        del dq[u]
        for y in range(n):
            if label[y] == u:
                label[y] = v
        A[v] += A[u]
        A[u] = 0
        if g.directed:
            B[v] += B[u]
            B[u] = 0
        dq = defaultdict(dict, {k: d for k, d in dq.items() if d})
    return label


# ---- Label propagation -------------------------------------------------------------------------


def votes(g, w, labels, u):
    """Label -> total weight of u's edges to it; self-loops vote for nothing (api.md)."""
    out = {}
    for (t, e) in g.rows[u]:
        if t != u:
            out[labels[t]] = out.get(labels[t], 0.0) + w[e]
    return out


def best_labels(vt):
    mx = max(vt.values())
    return [l for l, f in vt.items() if f == mx]


def semisync_model(g, w):
    assert not g.directed
    w = weights_of(g, w)
    n = g.n
    # Greedy coloring, largest degree first (ties by vertex number), loops ignored.
    order = sorted(range(n), key=lambda v: -len(g.rows[v]))
    color = [-1] * n
    for v in order:
        used = {color[t] for (t, _) in g.rows[v] if t != v and color[t] >= 0}
        c = 0
        while c in used:
            c += 1
        color[v] = c
    classes = [[v for v in range(n) if color[v] == c] for c in range(max(color, default=-1) + 1)]
    labels = list(range(n))

    def complete():
        for v in range(n):
            vt = votes(g, w, labels, v)
            if vt and labels[v] not in best_labels(vt):
                return False
        return True

    rounds = 0
    while not complete():
        rounds += 1
        assert rounds < 10000
        for cls in classes:
            for u in cls:
                vt = votes(g, w, labels, u)
                if not vt:
                    continue
                hb = best_labels(vt)
                if len(hb) == 1:
                    labels[u] = hb[0]
                elif labels[u] not in hb:
                    labels[u] = max(hb)
    return labels


def async_model(g, w, rng=None):
    assert not g.directed
    w = weights_of(g, w)
    labels = list(range(g.n))
    cont, sweeps = True, 0
    while cont:
        cont = False
        sweeps += 1
        assert sweeps < 10000
        order = list(range(g.n))
        if rng is not None:
            rng.shuffle(order)
        for u in order:
            vt = votes(g, w, labels, u)
            if not vt:
                continue
            hb = best_labels(vt)
            if labels[u] not in hb:
                labels[u] = rng.choice(hb) if rng is not None else max(hb)
                cont = True
    return labels


# --------------------------------------------------------------------------------------------
# Independent checks
# --------------------------------------------------------------------------------------------


def modularity_matrix(g, w, labels, gamma):
    n, m = g.n, sum(w)
    if m == 0:
        return 0.0
    A = [[0.0] * n for _ in range(n)]
    for e, (a, b) in enumerate(g.ends):
        A[a][b] += w[e]
        if not g.directed:
            A[b][a] += w[e]  # a loop: 2w on the diagonal
    kout = [sum(r) for r in A]
    kin = [sum(A[i][j] for i in range(n)) for j in range(n)]
    tot = 0.0
    for i in range(n):
        for j in range(n):
            if labels[i] == labels[j]:
                if g.directed:
                    tot += A[i][j] - gamma * kout[i] * kin[j] / m
                else:
                    tot += A[i][j] - gamma * kout[i] * kout[j] / (2 * m)
    return tot / m if g.directed else tot / (2 * m)


def to_nx(g, w, multi=True, loops=True):
    if multi:
        H = nx.MultiDiGraph() if g.directed else nx.MultiGraph()
    else:
        H = nx.DiGraph() if g.directed else nx.Graph()
    H.add_nodes_from(range(g.n))
    for e, (a, b) in enumerate(g.ends):
        if a == b and not loops:
            continue
        x = 1.0 if w is None else float(w[e])
        if not multi and H.has_edge(a, b):
            H[a][b]["weight"] += x
        else:
            H.add_edge(a, b, weight=x)
    return H


def nx_labels(n, comms):
    lab = [-1] * n
    for c, comm in enumerate(comms):
        for v in comm:
            lab[v] = c
    return lab


def same_partition(l1, l2):
    return canonical(l1) == canonical(l2)


class Fixed(random.Random):
    """The identity shuffle and api.md's tie rule, for NetworkX's own code."""

    def shuffle(self, x):
        pass

    def choice(self, seq):
        return max(seq)


_src = inspect.getsource(nx_louvain._one_level)
assert "if gain > best_gain:" in _src
exec(
    _src.replace(
        "if gain > best_gain:",
        "if gain > best_gain or (gain == best_gain and best_com != u_com and nbr_com > best_com):",
    ),
    nx_louvain.__dict__,
)


def simple(g):
    seen = set()
    for a, b in g.ends:
        k = (a, b) if g.directed else (min(a, b), max(a, b))
        if a == b or k in seen:
            return False
        seen.add(k)
    return True


# --------------------------------------------------------------------------------------------
# Catalog rows
# --------------------------------------------------------------------------------------------


def parse_partition(s):
    s = s.strip()
    assert s.startswith("[") and s.endswith("]"), s
    return [[vtok(x) for x in split_top(c.strip()[1:-1])] for c in split_top(s[1:-1])]


def parse_op(op):
    op = op.strip().strip("`")
    view = None
    m = re.match(r"directed\s*>\s*(.*)", op)
    if m:
        view, op = "directed", m.group(1)
    part, arg = None, None
    m = re.fullmatch(r"(.*\))\.(coverage|performance|count|community\(of: (.*)\))", op)
    if m:
        op, part, arg = m.group(1), m.group(2).split("(")[0], m.group(3)
    m = re.fullmatch(r"(\w+)\((.*)\)", op)
    assert m, op
    args = {}
    for p in split_top(m.group(2)):
        k, v = p.split(":", 1)
        args[k.strip()] = v.strip()
    return view, m.group(1), args, part, arg


def num(s):
    return float(s)


def weak_labels(g):
    parent = list(range(g.n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in g.ends:
        parent[find(a)] = find(b)
    roots, lab = {}, []
    for v in range(g.n):
        lab.append(roots.setdefault(find(v), len(roots)))
    return lab


def run(g, name, a, rng=None):
    """The model's value: ('part', labels) | ('num', x); raises Trap."""
    w = parse_weights(a["weight"], g.m) if "weight" in a else None
    gamma = num(a.get("resolution", "1"))
    if name in ("modularity", "partitionQuality"):
        w = weights_of(g, w)
        if name == "modularity":
            check_resolution(gamma)
        of = a["of"]
        labels = weak_labels(g) if of == "components" else labels_of_partition(g, parse_partition(of))
        if name == "modularity":
            return ("num", modularity_model(g, w, labels, gamma))
        return ("quality", quality_model(g, labels))
    if name == "louvainCommunities":
        return ("part", louvain_model(g, w, gamma, num(a.get("threshold", "1e-7")), rng))
    if name == "greedyModularityCommunities":
        return ("part", greedy_model(g, w, gamma))
    if name == "labelPropagationCommunities":
        return ("part", semisync_model(g, w))
    if name == "asynchronousLabelPropagationCommunities":
        return ("part", async_model(g, w, rng))
    raise AssertionError(name)


def fmt_num(x):
    return "#nan" if x != x else f"#{(0.0 if abs(x) < 1e-13 else x):.12g}"


def present(g, kind, val, part, arg):
    """The Expected cell's text for a model value."""
    if kind == "num":
        return fmt_num(val)
    if kind == "quality":
        return fmt_num(val[0] if part == "coverage" else val[1])
    groups = canonical(val)
    if part == "count":
        return f"#{len(groups)}"
    if part == "community":
        v = g.vertices.index(vtok(arg))
        return f"#{next(i for i, c in enumerate(groups) if v in c)}"
    return "[" + ", ".join("[" + ", ".join(str(g.vertices[v]) for v in c) + "]" for c in groups) + "]"


def evaluate(gcell, op):
    g = parse_graph(gcell)
    view, name, a, part, arg = parse_op(op)
    if view == "directed":
        base = g
        g = g.directed_view()
        if "weight" in a:
            ws = parse_weights(a["weight"], base.m)
            a = dict(a, weight="[" + ", ".join(str(ws[e // 2]) for e in range(g.m)) + "]")
    try:
        kind, val = run(g, name, a)
    except Trap:
        return g, name, a, part, arg, "trap", None, None
    return g, name, a, part, arg, present(g, kind, val, part, arg), kind, val


def close_text(got, exp, tol):
    if got == exp:
        return True
    if got.startswith("#") and exp.startswith("#"):
        x, y = float(got[1:]), float(exp[1:])
        if x != x or y != y:
            return x != x and y != y
        return abs(x - y) <= tol * max(1.0, abs(y))
    return False


def independent(g, name, a, part, arg, kind, val, tol):
    """Problems found by the independent checks (module docstring)."""
    probs = []
    w = weights_of(g, parse_weights(a["weight"], g.m) if "weight" in a else None)
    wn = None if "weight" not in a else w
    gamma = num(a.get("resolution", "1"))
    n = g.n
    if name == "modularity":
        labels = weak_labels(g) if a["of"] == "components" else labels_of_partition(g, parse_partition(a["of"]))
        mm = modularity_matrix(g, w, labels, gamma)
        if abs(mm - val) > max(tol, 1e-9):
            probs.append(f"matrix definition {mm} != {val}")
        comms = canonical(labels)
        q = nx.community.modularity(to_nx(g, w), comms, weight="weight", resolution=gamma)
        if abs(q - val) > max(tol, 1e-9):
            probs.append(f"NetworkX modularity {q} != {val}")
    elif name == "partitionQuality":
        if simple(g) and n >= 2 and g.m >= 1:
            labels = weak_labels(g) if a["of"] == "components" else labels_of_partition(g, parse_partition(a["of"]))
            cov, perf = nx.community.partition_quality(to_nx(g, None, multi=False), canonical(labels))
            if abs(cov - val[0]) > 1e-12 or abs(perf - val[1]) > 1e-12:
                probs.append(f"NetworkX partition_quality {(cov, perf)} != {val}")
    elif name == "louvainCommunities":
        thr = num(a.get("threshold", "1e-7"))
        if "using" in a:
            for i in range(200):
                got = louvain_model(g, wn, gamma, thr, random.Random(i))
                if not same_partition(got, val):
                    probs.append(f"order {i} gives {canonical(got)}")
                    break
            seeds = range(25)
        else:
            seeds = [Fixed()]
        for s in seeds:
            got = nx.community.louvain_communities(to_nx(g, w), weight="weight", resolution=gamma,
                                                   threshold=thr, seed=s)
            if not same_partition(nx_labels(n, got), val):
                probs.append(f"NetworkX louvain (seed {s}) {sorted(map(sorted, got))}")
                break
    elif name == "greedyModularityCommunities":
        if sum(w) > 0:
            got = nx.community.greedy_modularity_communities(to_nx(g, w), weight="weight", resolution=gamma)
            if not same_partition(nx_labels(n, got), val):
                probs.append(f"NetworkX greedy {sorted(map(sorted, got))}")
    elif name == "labelPropagationCommunities":
        if simple(g) and wn is None:
            got = nx.community.label_propagation_communities(to_nx(g, None, multi=False))
            if not same_partition(nx_labels(n, got), val):
                probs.append(f"NetworkX label_propagation {sorted(map(sorted, got))}")
    elif name == "asynchronousLabelPropagationCommunities":
        H = to_nx(g, w, multi=False, loops=False)
        if "using" in a:
            for i in range(200):
                got = async_model(g, wn, random.Random(i))
                if not same_partition(got, val):
                    probs.append(f"order {i} gives {canonical(got)}")
                    break
            seeds = range(25)
        else:
            seeds = [Fixed()]
        for s in seeds:
            got = nx.community.asyn_lpa_communities(H, weight="weight", seed=s)
            if not same_partition(nx_labels(n, list(got)), val):
                probs.append(f"NetworkX asyn_lpa (seed {s})")
                break
    return probs


def main():
    fill = "--fill" in sys.argv
    lines = CASES.read_text().splitlines()
    out, n_cases, problems, ids = [], 0, [], set()
    for line in lines:
        m = re.match(r"\| (CD-\d+) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \|(.*)$", line)
        if not m:
            out.append(line)
            continue
        cid, gcell, op, expc, tolc, rest = m.groups()
        assert cid not in ids, cid
        ids.add(cid)
        n_cases += 1
        g, name, a, part, arg, got, kind, val = evaluate(gcell, op)
        tol = 1e-12 if tolc.strip() == "exact" else float(tolc)
        if expc.strip() == "?" and fill:
            expc = f"`{got}`"
            line = f"| {cid} | {gcell} | {op} | {expc} | {tolc} |{rest}"
        out.append(line)
        if expc.strip() == "?":
            problems.append(f"{cid}: unfilled")
            continue
        exp = expc.strip().strip("`")
        if not close_text(got, exp, tol):
            problems.append(f"{cid}: catalog {exp} != model {got}")
            continue
        if got == "trap":
            continue
        problems += [f"{cid}: {p}" for p in independent(g, name, a, part, arg, kind, val, tol)]
    if fill:
        CASES.write_text("\n".join(out) + "\n")
    for p in problems:
        print(p)
    print(f"{n_cases} cases")
    if not problems:
        print("all values agree")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
