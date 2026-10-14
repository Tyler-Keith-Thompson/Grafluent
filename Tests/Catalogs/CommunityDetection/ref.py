"""Independent reference for the CommunityDetection module (catalog cases.md, CD-...).

Run:  uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 --with igraph==1.0.0 python3 ref.py
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
  for asynchronous label propagation, random tie choices), and NetworkX with 25 integer seeds;
* Girvan-Newman: the model recomputes Brandes' edge betweenness (floating point, the module's
  accumulation) on the whole remaining graph and removes the greatest, the least edge number on an
  exact tie. It is checked against the same method with edge betweenness by the definition in exact
  rational arithmetic (Fractions), and against NetworkX 3.7 `girvan_newman` on simple graphs when no
  removal up to the row's level ties (NetworkX breaks ties by its edge order);
* spectral clustering (Ng-Jordan-Weiss): the model takes the unit rows of N's k smallest
  eigenvectors (numpy eigh) and the labeling of least inertia over every labeling into k clusters
  (brute force, a unique least asserted). It is checked against Lloyd's iteration started from
  every k-subset of the rows, the least inertia kept. Rows pass `using: rng(1)`: the generator
  draws only the k-means++ seeds, and the least labeling is what the 10 seeded runs reach;
* the map equation's code length: the model's L(M) = f(Σ q_i) − 2 Σ f(q_i) − Σ f(p_v) +
  Σ f(q_i + p_i), checked against the entropy form q H(Q) + Σ_i p_i⟳ H(P_i).
"""

import inspect
import itertools
import math
import random
import re
import sys
from collections import Counter, defaultdict
from fractions import Fraction
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
        """graph.directedView: arc 2p forward, 2p+1 reversed; rows from incidentEdges order."""
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


def code_length_model(g, w, labels):
    """The two-level map equation (api.md): flow d_v / 2W at each vertex and w / 2W along each edge
    each way, a loop twice in its vertex's degree and never leaving a module; 0 when W = 0."""
    total = sum(w)
    if total == 0:
        return 0.0
    f = lambda x: x * math.log2(x) if x > 0 else 0.0
    n = len(g.vertices)
    p = [0.0] * n
    q = {}
    for e, (x, y) in enumerate(g.ends):
        p[x] += w[e] / (2 * total)
        p[y] += w[e] / (2 * total)
        if labels[x] != labels[y]:
            q[labels[x]] = q.get(labels[x], 0.0) + w[e] / (2 * total)
            q[labels[y]] = q.get(labels[y], 0.0) + w[e] / (2 * total)
    size = {}
    for v in range(n):
        size[labels[v]] = size.get(labels[v], 0.0) + p[v]
    exits = sum(q.values())
    return f(exits) - 2 * sum(f(x) for x in q.values()) - sum(f(x) for x in p) + sum(f(q.get(c, 0.0) + size[c]) for c in size)


def code_length_by_entropies(g, w, labels):
    """The same code length as q H(Q) + Σ_i p_i⟳ H(P_i), the index codebook's entropy weighted by
    the exit rate plus each module codebook's (its exits and its vertices) weighted by its use."""
    total = sum(w)
    if total == 0:
        return 0.0
    n = len(g.vertices)
    p = [0.0] * n
    q = {}
    for e, (x, y) in enumerate(g.ends):
        p[x] += w[e] / (2 * total)
        p[y] += w[e] / (2 * total)
        if labels[x] != labels[y]:
            q[labels[x]] = q.get(labels[x], 0.0) + w[e] / (2 * total)
            q[labels[y]] = q.get(labels[y], 0.0) + w[e] / (2 * total)

    def entropy(xs):
        t = sum(xs)
        return -sum(x / t * math.log2(x / t) for x in xs if x > 0) if t > 0 else 0.0
    exits = sum(q.values())
    length = exits * entropy(list(q.values()))
    for c in set(labels):
        members = [p[v] for v in range(n) if labels[v] == c]
        use = q.get(c, 0.0) + sum(members)
        length += use * entropy([q.get(c, 0.0)] + members)
    return length


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


def louvain_model(g, w, resolution=1.0, threshold=1e-7, rng=None, levels=None):
    """The final partition; every level's partition is appended to `levels` when given."""
    w = weights_of(g, w)
    check_resolution(resolution)
    if not finite(threshold) or threshold < 0:
        raise Trap()
    if g.m == 0:
        if levels is not None:
            levels.append(list(range(g.n)))
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
        if levels is not None:
            levels.append(labels)
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


# ---- The constant Potts model, Leiden, Kernighan-Lin, k-clique, Walktrap, leading eigenvector --


def cpm_model(g, w, labels, gamma):
    """Sum over communities of e_c - gamma n_c^2 / 2 (directed: - gamma n_c^2)."""
    k = max(labels) + 1 if labels else 0
    inside, size = [0.0] * k, [0] * k
    for c in labels:
        size[c] += 1
    for e, (a, b) in enumerate(g.ends):
        if labels[a] == labels[b]:
            inside[labels[a]] += w[e]
    scale = gamma if g.directed else gamma / 2
    return sum(inside[c] - scale * size[c] * size[c] for c in range(k))


def leiden_model(g, w, potts, gamma, theta, rng, iterations=None):
    """api.md's Leiden: the move phase from a queue in shuffled order (ties stay; an empty community
    is a choice), the refinement of each community from singletons (well-connected vertices join a
    well-connected neighboring refined community with gain >= 0, or stay, with probability
    proportional to exp(gain / theta)), aggregation of the refined communities, until the move phase
    leaves every level vertex alone or the refinement merges nothing; iterations until one changes
    nothing; then each community split into its connected parts. Gains as Swift computes them in
    units of edge weight (H = sum_c e_c - g' A_c B_c), exact comparisons with a tolerance of 1e-9
    relative for moves."""
    w = weights_of(g, w)
    check_resolution(gamma)
    if not finite(theta) or theta <= 0:
        raise Trap()
    n, directed = g.n, g.directed
    if n <= 1:
        return list(range(n))
    m = sum(w)
    if not potts and m == 0:
        return list(range(n))
    scale = (gamma / m if directed else gamma / (4 * m)) if not potts else (gamma if directed else gamma / 2)
    base = Level(n, directed)
    for e, (a, b) in enumerate(g.ends):
        base.add(a, b, w[e])
    base.prepare()
    a0 = base.out[:] if not potts else [1.0] * n
    b0 = base.inn[:] if not potts else [1.0] * n

    def move(lv, com, a, b):
        k = lv.k
        A, B, size = [0.0] * k, [0.0] * k, [0] * k
        for v in range(k):
            A[com[v]] += a[v]
            B[com[v]] += b[v]
            size[com[v]] += 1
        empty = [c for c in range(k - 1, -1, -1) if size[c] == 0]
        order = list(range(k))
        rng.shuffle(order)
        queue, queued = list(order), [True] * k
        head = 0
        while head < len(queue):
            v = queue[head]
            head += 1
            queued[v] = False
            cur = com[v]
            to = {}
            for u, x in lv.nbrs[v].items():
                to[com[u]] = to.get(com[u], 0.0) + x
            stay = to.get(cur, 0.0) - scale * (a[v] * (B[cur] - b[v]) + b[v] * (A[cur] - a[v]))
            best, chosen = stay, cur
            if size[cur] > 1 and -best > 1e-9 * max(1.0, abs(best)):
                best, chosen = 0.0, -1
            for c, x in to.items():
                if c == cur:
                    continue
                gain = x - scale * (a[v] * B[c] + b[v] * A[c])
                if gain - best > 1e-9 * max(1.0, abs(gain), abs(best)):
                    best, chosen = gain, c
            if chosen == cur:
                continue
            if chosen < 0:
                chosen = empty.pop()
            A[cur] -= a[v]
            B[cur] -= b[v]
            size[cur] -= 1
            if size[cur] == 0:
                empty.append(cur)
            A[chosen] += a[v]
            B[chosen] += b[v]
            size[chosen] += 1
            com[v] = chosen
            for u in lv.nbrs[v]:
                if not queued[u] and com[u] != chosen:
                    queued[u] = True
                    queue.append(u)
        return com

    def refine(lv, com, a, b):
        k = lv.k
        SA, SB = {}, {}
        for v in range(k):
            SA[com[v]] = SA.get(com[v], 0.0) + a[v]
            SB[com[v]] = SB.get(com[v], 0.0) + b[v]
        ext = [sum(x for u, x in lv.nbrs[v].items() if com[u] == com[v]) for v in range(k)]
        ref = list(range(k))
        rA, rB, rE, rS = a[:], b[:], ext[:], [1] * k
        order = list(range(k))
        rng.shuffle(order)
        for v in order:
            if ref[v] != v or rS[v] != 1:
                continue
            c = com[v]
            if ext[v] < scale * (a[v] * (SB[c] - b[v]) + b[v] * (SA[c] - a[v])):
                continue
            to = {}
            for u, x in lv.nbrs[v].items():
                if com[u] == c:
                    to[ref[u]] = to.get(ref[u], 0.0) + x
            cands = []
            for r, x in to.items():
                if rE[r] < scale * (rA[r] * (SB[c] - rB[r]) + rB[r] * (SA[c] - rA[r])):
                    continue
                gain = x - scale * (a[v] * rB[r] + b[v] * rA[r])
                if gain >= 0:
                    cands.append((r, gain))
            if not cands:
                continue
            most = max(0.0, max(gn for _, gn in cands))
            stay = math.exp((0 - most) / theta)
            chances = [math.exp((gn - most) / theta) for _, gn in cands]
            x = rng.random() * (stay + sum(chances))
            if x < stay:
                continue
            x -= stay
            pick = cands[-1][0]
            for (r, _), ch in zip(cands, chances):
                if x < ch:
                    pick = r
                    break
                x -= ch
            ref[v] = pick
            rA[pick] += a[v]
            rB[pick] += b[v]
            rS[pick] += 1
            rS[v] = 0
            rE[pick] += ext[v] - 2 * to[pick]
        return ref

    membership = list(range(n))
    it = 0
    while iterations is None or it < iterations:
        it += 1
        lv, a, b = base, a0[:], b0[:]
        node = list(range(n))
        com = membership[:]
        while True:
            com = move(lv, com, a, b)
            k = lv.k
            if len(set(com)) == k:
                break
            ref = refine(lv, com, a, b)
            reps = [v for v in range(k) if ref[v] == v]
            if len(reps) == k:
                break
            label = {r: i for i, r in enumerate(reps)}
            rank = {}
            for c in com:
                rank.setdefault(c, len(rank))
            cnt = len(reps)
            na, nb, nc = [0.0] * cnt, [0.0] * cnt, [0] * cnt
            for v in range(k):
                r = label[ref[v]]
                na[r] += a[v]
                nb[r] += b[v]
                nc[r] = rank[com[v]]
            nxt = Level(cnt, directed)
            for (x, y), z in lv.w.items():
                nxt.add(label[ref[x]], label[ref[y]], z)
            nxt.prepare()
            lv, a, b, com = nxt, na, nb, nc
            node = [label[ref[x]] for x in node]
        labels = [com[node[v]] for v in range(n)]
        if canonical(labels) == canonical(membership):
            break
        membership = labels
    # Connected parts.
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for x, y in g.ends:
        if membership[x] == membership[y]:
            parent[find(x)] = find(y)
    return [find(v) for v in range(n)]


def kl_model(g, w, start, iterations=10):
    """api.md's Kernighan-Lin: NetworkX's alternating single moves with its heap (ties to the
    earliest insertion, an entry stale when its value is not the vertex's current one), rows merged
    in incidentEdges order, loops left out."""
    w = weights_of(g, w)
    n = g.n
    side = [1 if v in start[0] else 0 for v in range(n)]
    nbrs = []
    for v in range(n):
        d = {}
        for (u, e) in g.rows[v]:
            if u != v:
                d[u] = d.get(u, 0.0) + w[e]
        nbrs.append(d)
    import heapq
    for _ in range(iterations):
        heaps, cur, count = [[], []], [dict(), dict()], [0, 0]

        def push(s, v, x):
            cur[s][v] = x
            heapq.heappush(heaps[s], (x, count[s], v))
            count[s] += 1
        for u in range(n):
            push(side[u], u, sum(x if side[v] == side[u] else -x for v, x in nbrs[u].items()))

        def pop(s):
            while True:
                x, _, v = heapq.heappop(heaps[s])
                if v in cur[s] and cur[s][v] == x:
                    del cur[s][v]
                    return v, x
        costs, total = [], 0.0
        while cur[0] and cur[1]:
            pair = []
            for s in (0, 1):
                u, x = pop(s)
                total += x
                pair.append(u)
                for v, y in nbrs[u].items():
                    t = side[v]
                    if v in cur[t]:
                        nv = cur[t][v] + 2 * (-y if t == side[u] else y)
                        if nv != cur[t][v]:
                            push(t, v, nv)
            costs.append((total, len(costs) + 1, tuple(pair)))
        if not costs:
            break
        best, length, _ = min(costs)
        if best >= 0:
            break
        for _, _, (u, v) in costs[:length]:
            side[u], side[v] = 1, 0
    return side if n >= 2 else [0] * n


def kclique_model(g, k):
    """The unions of k-cliques joined through k - 1 shared vertices, by brute force over k-subsets."""
    from itertools import combinations
    adj = set()
    for a, b in g.ends:
        if a != b:
            adj.add((a, b))
            adj.add((b, a))
    cliques = [c for c in combinations(range(g.n), k) if all((x, y) in adj for x, y in combinations(c, 2))]
    parent = list(range(len(cliques)))

    def find(x):
        while parent[x] != x:
            x = parent[x]
        return x
    for i in range(len(cliques)):
        for j in range(i + 1, len(cliques)):
            if len(set(cliques[i]) & set(cliques[j])) == k - 1:
                parent[find(i)] = find(j)
    groups = {}
    for i, c in enumerate(cliques):
        groups.setdefault(find(i), set()).update(c)
    return sorted(sorted(c) for c in groups.values())


def walktrap_model(g, w, steps=4, lance_williams=False):
    """Walktrap by api.md, dense: each vertex gets a loop of its mean incident (merged) weight, 1 if
    that is 0; Ward merges of adjacent communities by least delta-sigma, ties to the least pair of
    community numbers (vertices 0..n-1, the k-th merge n + k), every delta-sigma recomputed from the
    walk vectors (or, with `lance_williams`, by that update where both merged communities are
    adjacent); the cut of greatest modularity, the earliest on a tie."""
    import numpy as np
    w = weights_of(g, w)
    n = g.n
    if steps < 1:
        raise Trap()
    if n <= 1:
        return list(range(n))
    A = np.zeros((n, n))
    loops = [0.0] * n
    adjacent = [set() for _ in range(n)]
    for e, (a, b) in enumerate(g.ends):
        if a == b:
            loops[a] += w[e]
        else:
            A[a, b] += w[e]
            A[b, a] += w[e]
            adjacent[a].add(b)
            adjacent[b].add(a)
    sums = A.sum(1)
    added = [sums[v] / len(adjacent[v]) if adjacent[v] and sums[v] > 0 else 1.0 for v in range(n)]
    B = A + np.diag(added)
    d = B.sum(1)
    P = np.linalg.matrix_power(B / d[:, None], steps)
    X = P / np.sqrt(d)[None, :]
    vec = {v: X[v] for v in range(n)}
    size = {v: 1.0 for v in range(n)}
    adj = {v: set(adjacent[v]) for v in range(n)}
    sig = {}

    def dist(x, y):
        return size[x] * size[y] / (size[x] + size[y]) * float(((vec[x] - vec[y]) ** 2).sum()) / n
    for a in range(n):
        for b in adj[a]:
            sig[(min(a, b), max(a, b))] = dist(a, b)
    labels = list(range(n))
    groups = {v: [v] for v in range(n)}
    best_q = modularity_model(g, w, labels, 1.0)
    best = labels[:]
    nxt = n
    while sig:
        (a, b) = min(sig, key=lambda k: (sig[k], k))
        ab = sig.pop((a, b))
        c = nxt
        nxt += 1
        vec[c] = (size[a] * vec[a] + size[b] * vec[b]) / (size[a] + size[b])
        size[c] = size[a] + size[b]
        groups[c] = groups.pop(a) + groups.pop(b)
        neighbors = (adj.pop(a) | adj.pop(b)) - {a, b}
        adj[c] = neighbors
        for x in neighbors:
            sa = sig.pop((min(a, x), max(a, x)), None)
            sb = sig.pop((min(b, x), max(b, x)), None)
            adj[x] -= {a, b}
            adj[x].add(c)
            if lance_williams and sa is not None and sb is not None:
                sig[(x, c)] = ((size[a] + size[x]) * sa + (size[b] + size[x]) * sb - size[x] * ab) / (size[a] + size[b] + size[x])
            else:
                sig[(x, c)] = dist(x, c)
        for v in groups[c]:
            labels[v] = c
        q = modularity_model(g, w, labels, 1.0)
        if q > best_q:
            best_q, best = q, labels[:]
    return best


def leading_model(g, w):
    """Newman's leading eigenvector, dense (numpy eigh): split a community by the signs of B^(g)'s
    leading eigenvector (entries 0 up to 1e-10 of the largest together on the side of greater gain)
    while its eigenvalue and the split's gain are
    positive; singletons when the total weight is 0."""
    import numpy as np
    w = weights_of(g, w)
    n = g.n
    A = np.zeros((n, n))
    k = np.zeros(n)
    for e, (a, b) in enumerate(g.ends):
        k[a] += w[e]
        k[b] += w[e]
        if a != b:
            A[a, b] += w[e]
            A[b, a] += w[e]
    m2 = k.sum()
    if m2 == 0:
        return list(range(n))
    labels = [0] * n
    count = 1
    pending = [list(range(n))]
    while pending:
        grp = pending.pop()
        s = len(grp)
        if s < 2:
            continue
        kg = k[grp].sum()
        Bg = A[np.ix_(grp, grp)] - np.outer(k[grp], k[grp]) / m2
        Bg -= np.diag(A[np.ix_(grp, grp)].sum(1) - k[grp] * kg / m2)
        vals, vecs = np.linalg.eigh(Bg)
        lam, x = vals[-1], vecs[:, -1]
        bound = max(1.0, float(np.max(2 * (A[np.ix_(grp, grp)].sum(1) + k[grp] * kg / m2))))
        if lam <= 1e-8 * bound:
            continue
        zero = 1e-10 * float(np.max(np.abs(x)))
        best, split = -math.inf, None
        for zs in (-1.0, 1.0):
            cand = np.array([1.0 if (v > zero or (abs(v) <= zero and zs > 0)) else -1.0 for v in x])
            pos = int((cand > 0).sum())
            if pos in (0, s):
                continue
            q = float(cand @ Bg @ cand)
            if q > best:
                best, split = q, cand
        if split is None or best <= 1e-10 * bound * s:
            continue
        first = [v for v, z in zip(grp, split) if z < 0]
        second = [v for v, z in zip(grp, split) if z > 0]
        for v in second:
            labels[v] = count
        count += 1
        pending += [first, second]
    return labels


# ---- Greedy modularity (Clauset-Newman-Moore) ------------------------------------------------


def spectral_rows(g, w, k):
    """Ng–Jordan–Weiss: the eigenvectors of N = I − D^-1/2 A D^-1/2 (a zero row and column at degree
    0) for its k smallest eigenvalues as columns (numpy eigh), each row scaled to unit length (a
    zero row stays zero). The k smallest eigenvalues must stand apart from the next, so the rows are
    determined up to a rotation, which k-means ignores. The rows here have no self-loops."""
    import numpy as np
    assert all(a != b for a, b in g.ends), "spectral clustering rows have no self-loops"
    A = np.zeros((g.n, g.n))
    for (a, b), x in zip(g.ends, w):
        A[a, b] += x
        A[b, a] += x
    d = A.sum(axis=1)
    N = np.zeros((g.n, g.n))
    for i in range(g.n):
        if d[i] > 0:
            N[i, i] = 1
        for j in range(g.n):
            if A[i, j] != 0:
                N[i, j] -= A[i, j] / math.sqrt(d[i] * d[j])
    vals, vecs = np.linalg.eigh(N)
    if k < g.n:
        assert vals[k] - vals[k - 1] > 1e-6, "the k smallest eigenvalues of N are not apart from the next"
    U = vecs[:, :k]
    return np.array([r / np.linalg.norm(r) if np.linalg.norm(r) > 0 else r for r in U])


def inertia_of(rows, labels, k):
    total = 0.0
    for c in range(k):
        members = rows[[i for i in range(len(labels)) if labels[i] == c]]
        total += float(((members - members.mean(axis=0)) ** 2).sum())
    return total


def spectral_model(g, w, k):
    """api.md's spectral clustering: the labeling of least inertia over every labeling of the unit
    rows into exactly k nonempty clusters, by brute force (n <= 10); a unique least is asserted."""
    if k < 1 or k > g.n:
        raise Trap()
    w = weights_of(g, w)
    rows = spectral_rows(g, w, k)
    found = []
    for labels in itertools.product(range(k), repeat=g.n):
        if labels[0] != 0 or len(set(labels)) != k:
            continue
        seen = []
        for x in labels:
            if x not in seen:
                seen.append(x)
        if seen != sorted(seen):
            continue
        found.append((inertia_of(rows, labels, k), labels))
    found.sort()
    assert len(found) == 1 or found[1][0] - found[0][0] > 1e-9, ("two labelings of least inertia", found[:2])
    return list(found[0][1])


def lloyd_from_every_start(g, w, k):
    """The least-inertia result of Lloyd's iteration started from every k-subset of the rows as
    centers (nearest center, least on ties; a cluster that empties is dropped from the start)."""
    import numpy as np
    rows = spectral_rows(g, weights_of(g, w), k)
    best = None
    for start in itertools.combinations(range(g.n), k):
        centers = rows[list(start)].copy()
        labels = None
        for _ in range(300):
            new = [min(range(k), key=lambda c: (float(((r - centers[c]) ** 2).sum()), c)) for r in rows]
            if new == labels:
                break
            labels = new
            if len(set(labels)) < k:
                break
            centers = np.array([rows[[i for i in range(g.n) if labels[i] == c]].mean(axis=0) for c in range(k)])
        if len(set(labels)) < k:
            continue
        x = inertia_of(rows, labels, k)
        if best is None or x < best[0] - 1e-12:
            best = (x, labels)
    return best[1]


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
    level = None
    m = re.fullmatch(r"(.*\))\[(\d+)\]", op)
    if m:
        op, level = m.group(1), m.group(2)
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
    if level is not None:
        args["level"] = level
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


def components_of(n, ends, alive):
    """Component labels over the edges alive."""
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for e, (a, b) in enumerate(ends):
        if alive[e]:
            parent[find(a)] = find(b)
    return [find(v) for v in range(n)]


def edge_scores_model(g, alive):
    """Ordered-pair edge betweenness of the edges alive, Brandes' edge accumulation in floating
    point over the rows (loops dropped), as the module accumulates it."""
    n = g.n
    rows = [[(t, e) for (t, e) in g.rows[v] if alive[e] and t != v] for v in range(n)]
    eb = [0.0] * g.m
    for s in range(n):
        dist, sigma = [None] * n, [0.0] * n
        dist[s], sigma[s] = 0, 1.0
        order = [s]
        for v in order:
            for t, e in rows[v]:
                if dist[t] is None:
                    dist[t] = dist[v] + 1
                    order.append(t)
                if dist[t] == dist[v] + 1:
                    sigma[t] += sigma[v]
        delta = [0.0] * n
        for v in reversed(order):
            for t, e in rows[v]:
                if dist[t] == dist[v] + 1:
                    c = sigma[v] / sigma[t] * (1 + delta[t])
                    eb[e] += c
                    delta[v] += c
    return eb


def edge_scores_exact(g, alive):
    """The same by the definition, in Fractions: sum over ordered pairs and arcs a -> b on a
    shortest path of sigma_sa sigma_bt / sigma_st."""
    n = g.n
    arcs = []
    for e, (a, b) in enumerate(g.ends):
        if alive[e] and a != b:
            arcs += [(e, a, b), (e, b, a)]
    D = [[None] * n for _ in range(n)]
    S = [[0] * n for _ in range(n)]
    for s in range(n):
        D[s][s], S[s][s] = 0, 1
        frontier, depth = [s], 0
        while frontier:
            depth += 1
            nxt = []
            for _, a, b in arcs:
                if D[s][a] == depth - 1:
                    if D[s][b] is None:
                        D[s][b] = depth
                        nxt.append(b)
                    if D[s][b] == depth:
                        S[s][b] += S[s][a]
            frontier = nxt
    eb = [Fraction(0)] * g.m
    for s in range(n):
        for t in range(n):
            if s == t or D[s][t] is None:
                continue
            for e, a, b in arcs:
                if D[s][a] is not None and D[b][t] is not None and D[s][a] + 1 + D[b][t] == D[s][t]:
                    eb[e] += Fraction(S[s][a] * S[b][t], S[s][t])
    return eb


def girvan_newman_model(g, scores=edge_scores_model):
    """The levels (component labels each time their number grows) and, for each level, whether a
    removal up to it was a tie of the greatest score."""
    alive = [a != b for a, b in g.ends]
    if not any(alive):
        return [components_of(g.n, g.ends, alive)], [False]
    levels, tied, any_tie = [], [], False
    count = len(set(components_of(g.n, g.ends, alive)))
    while any(alive):
        eb = scores(g, alive)
        live = [e for e in range(g.m) if alive[e]]
        best = max(eb[e] for e in live)
        top = [e for e in live if eb[e] == best]
        any_tie |= len(top) > 1
        alive[top[0]] = False
        labels = components_of(g.n, g.ends, alive)
        if len(set(labels)) > count:
            count = len(set(labels))
            levels.append(labels)
            tied.append(any_tie)
    return levels, tied


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
    if name == "girvanNewmanCommunities":
        levels, _ = girvan_newman_model(g)
        return ("part", levels[int(a["level"])])
    if name == "codeLength":
        w = weights_of(g, w)
        return ("num", code_length_model(g, w, labels_of_partition(g, parse_partition(a["of"]))))
    if name == "constantPottsModel":
        w = weights_of(g, w)
        check_resolution(gamma)
        return ("num", cpm_model(g, w, labels_of_partition(g, parse_partition(a["of"])), gamma))
    if name == "leidenCommunities":
        iterations = int(a["iterations"]) if "iterations" in a else None
        if iterations is not None and iterations < 1:
            raise Trap()
        potts = a.get("quality") == "constantPottsModel"
        return ("part", leiden_model(g, w, potts, gamma, num(a.get("randomness", "0.01")), rng or random.Random(0), iterations))
    if name == "louvainPartitions":
        levels = []
        louvain_model(g, w, gamma, num(a.get("threshold", "1e-7")), rng, levels)
        return ("part", levels[int(a["level"])])
    if name == "kernighanLinBisection":
        start = parse_partition(a["startingFrom"])
        if len(start) != 2:
            raise Trap()
        iterations = int(a.get("iterations", "10"))
        if iterations < 0:
            raise Trap()
        first = {g.vertices.index(v) for v in start[0]}
        return ("part", kl_model(g, w, (first, None), iterations))
    if name == "kCliqueCommunities":
        k = int(a["k"])
        if k < 2:
            raise Trap()
        return ("cover", kclique_model(g, k))
    if name == "walktrapCommunities":
        return ("part", walktrap_model(g, w, int(a.get("steps", "4"))))
    if name == "leadingEigenvectorCommunities":
        return ("part", leading_model(g, w))
    if name == "spectralClustering":
        return ("part", spectral_model(g, w, int(a["clusterCount"])))
    raise AssertionError(name)


def fmt_num(x):
    return "#nan" if x != x else f"#{(0.0 if abs(x) < 1e-13 else x):.12g}"


def present(g, kind, val, part, arg):
    """The Expected cell's text for a model value."""
    if kind == "num":
        return fmt_num(val)
    if kind == "quality":
        return fmt_num(val[0] if part == "coverage" else val[1])
    if kind == "cover":
        return "[" + ", ".join("[" + ", ".join(str(g.vertices[v]) for v in c) + "]" for c in val) + "]"
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
    elif name == "girvanNewmanCommunities":
        k = int(a["level"])
        exact, tied = girvan_newman_model(g, edge_scores_exact)
        if not same_partition(exact[k], val):
            probs.append(f"exact arithmetic gives {canonical(exact[k])}")
        if simple(g) and not tied[k] and any(x != y for x, y in g.ends):
            H = nx.Graph()
            H.add_nodes_from(range(n))
            H.add_edges_from(g.ends)
            got = None
            for i, level in enumerate(nx.community.girvan_newman(H)):
                if i == k:
                    got = level
                    break
            if got is None or not same_partition(nx_labels(n, list(got)), val):
                probs.append(f"NetworkX girvan_newman level {k}: {got}")
    elif name == "codeLength":
        labels = labels_of_partition(g, parse_partition(a["of"]))
        entropies = code_length_by_entropies(g, w, labels)
        if abs(entropies - val) > max(tol, 1e-9):
            probs.append(f"by entropies {entropies} != {val}")
    elif name == "constantPottsModel":
        labels = labels_of_partition(g, parse_partition(a["of"]))
        comms = canonical(labels)
        H = nx.DiGraph() if g.directed else nx.Graph()
        if simple(g):
            H.add_nodes_from(range(n))
            for e, (x, y) in enumerate(g.ends):
                H.add_edge(x, y, weight=w[e])
            q = nx.community.constant_potts_model(H, comms, weight="weight", resolution=gamma)
            if abs(q - val) > max(tol, 1e-9):
                probs.append(f"NetworkX constant_potts_model {q} != {val}")
        # The definition by pairs: Σ_c e_c − γ' n_c².
        direct = sum(w[e] for e, (x, y) in enumerate(g.ends) if labels[x] == labels[y])
        direct -= sum((gamma if g.directed else gamma / 2) * labels.count(c) ** 2 for c in set(labels))
        if abs(direct - val) > max(tol, 1e-9):
            probs.append(f"by pairs {direct} != {val}")
    elif name == "leidenCommunities":
        potts = a.get("quality") == "constantPottsModel"
        theta = num(a.get("randomness", "0.01"))
        for i in range(200):
            got = leiden_model(g, wn, potts, gamma, theta, random.Random(i))
            if not same_partition(got, val):
                probs.append(f"order {i} gives {canonical(got)}")
                break
        if g.m > 0:
            H = nx.DiGraph() if g.directed else nx.Graph()
            H.add_nodes_from(range(n))
            for e, (x, y) in enumerate(g.ends):
                if H.has_edge(x, y):
                    H[x][y]["weight"] += w[e]
                else:
                    H.add_edge(x, y, weight=w[e])
            for seed in range(25):
                got = nx.community.leiden_communities(H, weight="weight", resolution=gamma, seed=seed,
                                                      metric="cpm" if potts else "modularity")
                if not same_partition(nx_labels(n, got), val):
                    probs.append(f"NetworkX leiden (seed {seed}) {sorted(map(sorted, got))}")
                    break
    elif name == "louvainPartitions":
        k = int(a["level"])
        H = to_nx(g, w)
        got = list(nx.community.louvain_partitions(H, weight="weight", resolution=gamma, seed=Fixed()))
        if k >= len(got) or not same_partition(nx_labels(n, got[k]), val):
            probs.append(f"NetworkX louvain_partitions level {k}")
    elif name == "kernighanLinBisection":
        start = parse_partition(a["startingFrom"])
        H = nx.Graph()
        H.add_nodes_from(range(n))
        for e, (x, y) in enumerate(g.ends):
            if x != y:
                if H.has_edge(x, y):
                    H[x][y]["weight"] += w[e]
                else:
                    H.add_edge(x, y, weight=w[e])
        first = {g.vertices.index(v) for v in start[0]}
        second = set(range(n)) - first
        got = nx.community.kernighan_lin_bisection(H, partition=(first, second), max_iter=int(a.get("iterations", "10")), weight="weight")
        lab = [0 if v in got[0] else 1 for v in range(n)]
        if not same_partition(lab, val):
            probs.append(f"NetworkX kernighan_lin_bisection {got}")
    elif name == "kCliqueCommunities":
        H = nx.Graph()
        H.add_nodes_from(range(n))
        H.add_edges_from((x, y) for x, y in g.ends if x != y)
        got = sorted(sorted(c) for c in nx.community.k_clique_communities(H, int(a["k"])))
        if got != val:
            probs.append(f"NetworkX k_clique_communities {got}")
    elif name == "walktrapCommunities":
        got = walktrap_model(g, wn, int(a.get("steps", "4")), lance_williams=True)
        if not same_partition(got, val):
            probs.append(f"Lance–Williams updates give {canonical(got)}")
    elif name == "leadingEigenvectorCommunities":
        import igraph
        G = igraph.Graph(n=n, edges=g.ends)
        got = G.community_leading_eigenvector(weights=w if g.m else None).membership
        if not same_partition(got, val):
            probs.append(f"igraph community_leading_eigenvector {canonical(got)}")
    elif name == "spectralClustering":
        got = lloyd_from_every_start(g, wn, int(a["clusterCount"]))
        if not same_partition(got, val):
            probs.append(f"Lloyd's iteration from every start gives {canonical(got)}")
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
