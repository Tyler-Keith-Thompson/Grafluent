#!/usr/bin/env python3
"""Reference model for the RandomGraphs factories (Tests/Catalogs/RandomGraphs).

Run: uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/RandomGraphs/ref.py [--write] [--stress]

The model ports the pinned procedures of api.md draw for draw:
  * the generator: Xoshiro256StarStar seeded through SplitMix64 (Vigna's reference code; the
    seeding is rand_xoshiro's seed_from_u64), checked against published test vectors;
  * the two draws every procedure makes, and nothing else: uniform01() = (next() >> 11) * 2^-53 and
    below(n), CPython's _randbelow_with_getrandbits with getrandbits(k) = next() >> (64 - k);
  * each family's procedure.
Because the two draws are exactly what CPython's random.Random uses for random() and choice(),
StreamRandom (a random.Random over the same stream) lets NetworkX 3.7 run its own generator on our
stream. Every row marked `= NetworkX` is checked edge for edge against it: fast_gnp_random_graph,
gnm_random_graph, watts_strogatz_graph, random_geometric_graph (no scipy, so NetworkX takes its
pairwise loop), stochastic_block_model (when CPython's set iteration of each block is ascending),
barabasi_albert_graph (when CPython's set iteration of each target set is ascending), and
random_labeled_tree. igraph checks the structural laws (is_tree, is_dag, simplicity).

Statistical rows run the pinned procedure over seeds 0..<S and record the exact aggregate (the
Swift suite can assert it exactly) together with the law it must satisfy (|z| <= 4 against the
expectation, or a chi-square below its 0.999 quantile).

--write regenerates cases.md; without it the run fails if cases.md differs. --stress checks the
NetworkX equivalences over many more seeds and sizes.
"""
import itertools
import math
import os
import random
import sys

import igraph as ig
import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))
MASK = (1 << 64) - 1


class Trap(Exception):
    pass


def require(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------- the generator and the two draws

def rotl(x, k):
    return ((x << k) | (x >> (64 - k))) & MASK


class SplitMix64:
    def __init__(self, seed):
        self.state = seed & MASK

    def next(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)


class Xoshiro256StarStar:
    """xoshiro256** 1.0 (Blackman and Vigna); init(seed:) fills the state with SplitMix64."""

    def __init__(self, seed=None, state=None):
        if state is None:
            sm = SplitMix64(seed)
            state = [sm.next() for _ in range(4)]
        self.s = list(state)
        self.draws = 0

    def next(self):
        s = self.s
        result = (rotl((s[1] * 5) & MASK, 7) * 9) & MASK
        t = (s[1] << 17) & MASK
        s[2] ^= s[0]
        s[3] ^= s[1]
        s[1] ^= s[2]
        s[0] ^= s[3]
        s[2] ^= t
        s[3] = rotl(s[3], 45)
        self.draws += 1
        return result

    # The two draws. Every procedure uses only these.
    def uniform01(self):
        return (self.next() >> 11) * (2.0 ** -53)

    def below(self, n):
        assert n >= 1
        k = n.bit_length()
        r = self.next() >> (64 - k)
        while r >= n:
            r = self.next() >> (64 - k)
        return r


class StreamRandom(random.Random):
    """A random.Random whose random(), getrandbits() and _randbelow() read our stream, so that
    NetworkX's generators can run on it."""

    def __init__(self, seed):
        self.stream = Xoshiro256StarStar(seed)
        super().__init__(0)

    def random(self):
        return self.stream.uniform01()

    def getrandbits(self, k):
        if k == 0:
            return 0
        assert 1 <= k <= 64
        return self.stream.next() >> (64 - k)

    def _randbelow(self, n):
        return self.stream.below(n)


def check_vectors():
    # xoshiro256** from state [1, 2, 3, 4]: rand_xoshiro's test vector (from Vigna's reference code).
    x = Xoshiro256StarStar(state=[1, 2, 3, 4])
    got = [x.next() for _ in range(10)]
    assert got == [11520, 0, 1509978240, 1215971899390074240, 1216172134540287360,
                   607988272756665600, 16172922978634559625, 8476171486693032832,
                   10595114339597558777, 2904607092377533576], got
    # SplitMix64 seeded with 1234567: the vector of Vigna's splitmix64.c test harness.
    sm = SplitMix64(1234567)
    got = [sm.next() for _ in range(5)]
    assert got == [6457827717110365317, 3203168211198807973, 9817491932198370423,
                   4593380528125082431, 16408922859458223821], got
    # CPython's own draws agree with ours when they read the same bits.
    r = StreamRandom(7)
    s = Xoshiro256StarStar(7)
    assert [r.random() for _ in range(5)] == [s.uniform01() for _ in range(5)]
    assert [r.choice(range(10)) for _ in range(20)] == [s.below(10) for _ in range(20)]


# ---------------------------------------------------------------- results

class R:
    def __init__(self, n, edges, directed, positions=None, code=None, sort=True):
        self.n = n
        self.directed = directed
        if sort:
            if directed:
                edges = sorted(edges)
            else:
                edges = sorted((min(u, v), max(u, v)) for u, v in edges)
            assert len(set(edges)) == len(edges), "repeated edge"
        self.edges = edges
        self.positions = positions
        self.code = code
        assert all(u != v for u, v in edges), "self-loop"
        assert all(0 <= u < n and 0 <= v < n for u, v in edges)

    def key(self):
        if self.directed:
            return self.n, set(self.edges)
        return self.n, {(min(u, v), max(u, v)) for u, v in self.edges}


def nx_key(H):
    if H.is_directed():
        return H.number_of_nodes(), set(H.edges())
    return H.number_of_nodes(), {(min(u, v), max(u, v)) for u, v in H.edges()}


def _count(n):
    require(isinstance(n, int) and n >= 0, f"vertexCount {n} is negative")


def _probability(p, name):
    require(isinstance(p, float) and not math.isnan(p) and 0.0 <= p <= 1.0, f"{name} {p} is not in 0...1")


# ---------------------------------------------------------------- procedures

def gnp(n, p, rng, directed=False):
    """NetworkX fast_gnp_random_graph (Batagelj–Brandes), with the edge cases of gnp_random_graph."""
    _count(n)
    _probability(p, "edgeProbability")
    if p >= 1.0:
        pairs = itertools.permutations(range(n), 2) if directed else itertools.combinations(range(n), 2)
        return R(n, list(pairs), directed)
    if p <= 0.0:
        return R(n, [], directed)
    lp = math.log(1.0 - p)
    if lp == 0.0:  # 1 - p rounds to 1: no edge can be drawn (NetworkX divides by zero)
        return R(n, [], directed)
    edges = []

    def sweep(emit):
        v, w = 1, -1
        while v < n:
            lr = math.log(1.0 - rng.uniform01())
            skip = lr / lp
            if not skip < n * n:  # past every remaining pair; Swift must not convert it to Int
                return
            w = w + 1 + int(skip)
            while w >= v and v < n:
                w -= v
                v += 1
            if v < n:
                emit(v, w)

    if directed:
        sweep(lambda v, w: edges.append((w, v)))  # first pass: lower index -> higher
    sweep(lambda v, w: edges.append((v, w)))
    return R(n, edges, directed)


def gnm(n, m, rng, directed=False):
    """NetworkX gnm_random_graph's rejection loop while 2m <= N; above that, the same loop picks the
    N - m pairs left out."""
    _count(n)
    N = n * (n - 1) if directed else n * (n - 1) // 2
    require(isinstance(m, int) and 0 <= m <= N, f"edgeCount {m} is not in 0...{N}")
    k = m if 2 * m <= N else N - m
    chosen = set()
    order = []
    while len(order) < k:
        u = rng.below(n)
        v = rng.below(n)
        if u == v:
            continue
        key = (u, v) if directed else (min(u, v), max(u, v))
        if key in chosen:
            continue
        chosen.add(key)
        order.append(key)
    if k == m:
        return R(n, order, directed)
    pairs = itertools.permutations(range(n), 2) if directed else itertools.combinations(range(n), 2)
    return R(n, [e for e in pairs if e not in chosen], directed)


def barabasi_albert(n, m, rng, directed=False, networkx_order=False):
    """NetworkX barabasi_albert_graph with the default star seed; each new vertex's targets are
    appended to the repeated list in ascending order (NetworkX: CPython set order)."""
    _count(n)
    require(1 <= m < n, f"edgesPerVertex {m} is not in 1..<{n}")
    edges = [(0, i) for i in range(1, m + 1)]
    repeated = [0] * m + list(range(1, m + 1))
    for source in range(m + 1, n):
        targets = set()
        while len(targets) < m:
            targets.add(repeated[rng.below(len(repeated))])
        ordered = list(targets) if networkx_order else sorted(targets)
        edges.extend((source, t) for t in ordered)
        repeated.extend(ordered)
        repeated.extend([source] * m)
    if directed:  # igraph's orientation: new vertex -> older vertex
        return R(n, [(max(u, v), min(u, v)) for u, v in edges], True)
    return R(n, edges, False)


def ba_set_order_is_ascending(n, m, seed):
    """Whether NetworkX's set iteration equals ascending order at every step for this seed."""
    rng = Xoshiro256StarStar(seed)
    repeated = [0] * m + list(range(1, m + 1))
    for source in range(m + 1, n):
        targets = set()
        while len(targets) < m:
            targets.add(repeated[rng.below(len(repeated))])
        if list(targets) != sorted(targets):
            return False
        repeated.extend(targets)
        repeated.extend([source] * m)
    return True


def both_arcs(r):
    """The directed form of a symmetric family: both arcs of every edge (as complete and grid)."""
    return R(r.n, r.edges + [(v, u) for u, v in r.edges], True, positions=r.positions)


def watts_strogatz(n, k, p, rng, directed=False):
    """NetworkX watts_strogatz_graph, draw for draw; directed, both arcs of every edge."""
    if directed:
        return both_arcs(watts_strogatz(n, k, p, rng))
    _count(n)
    require(isinstance(k, int) and k >= 0 and k % 2 == 0, f"nearestNeighborCount {k} is not even")
    require(k <= n, f"nearestNeighborCount {k} > vertexCount {n}")
    _probability(p, "rewiringProbability")
    if k == n:
        return R(n, list(itertools.combinations(range(n), 2)), False)
    adj = [set() for _ in range(n)]
    for j in range(1, k // 2 + 1):
        for u in range(n):
            v = (u + j) % n
            adj[u].add(v)
            adj[v].add(u)
    for j in range(1, k // 2 + 1):
        for u in range(n):
            v = (u + j) % n
            if rng.uniform01() < p:
                w = rng.below(n)
                rewire = True
                while w == u or w in adj[u]:
                    w = rng.below(n)
                    if len(adj[u]) >= n - 1:
                        rewire = False
                        break
                if rewire:
                    adj[u].discard(v)
                    adj[v].discard(u)
                    adj[u].add(w)
                    adj[w].add(u)
    return R(n, [(u, v) for u in range(n) for v in adj[u] if u < v], False)


def random_geometric(n, radius, rng, dimension=2, directed=False):
    """NetworkX random_geometric_graph (Euclidean): positions vertex by vertex, coordinate by
    coordinate; u–v when sum of (a - b)^2 <= radius^2, summed in coordinate order. Directed: both
    arcs of every edge."""
    if directed:
        return both_arcs(random_geometric(n, radius, rng, dimension))
    _count(n)
    require(isinstance(radius, float) and not math.isnan(radius) and radius >= 0.0, f"radius {radius} is negative or NaN")
    require(dimension >= 1, f"dimension {dimension} < 1")
    pos = [[rng.uniform01() for _ in range(dimension)] for _ in range(n)]
    r2 = radius * radius
    edges = []
    for u in range(n):
        for v in range(u + 1, n):
            s = 0.0
            for a, b in zip(pos[u], pos[v]):
                s += (a - b) * (a - b)
            if s <= r2:
                edges.append((u, v))
    return R(n, edges, False, positions=pos)


def random_regular(n, d, rng, directed=False):
    """NetworkX random_regular_graph(d, n): the stubs 0..<n repeated d times, shuffled by CPython's
    shuffle (i from the last index down to 1, swapped with below(i + 1)) and paired in order; a
    self-loop or repeat keeps both stubs, by vertex in first-kept order, for the next round; a
    round whose kept vertices cannot form a new edge restarts the attempt. Directed: both arcs."""
    if directed:
        return both_arcs(random_regular(n, d, rng))
    _count(n)
    require(isinstance(d, int) and 0 <= d < n, f"degree {d} is not in 0..<{n}")
    require(n * d % 2 == 0, f"vertexCount × degree {n * d} is odd")
    if d == 0:
        return R(n, [], False)

    def shuffle(x):
        for i in reversed(range(1, len(x))):
            j = rng.below(i + 1)
            x[i], x[j] = x[j], x[i]

    while True:
        edges = set()
        order = []
        stubs = list(range(n)) * d
        failed = False
        while stubs:
            kept = {}
            shuffle(stubs)
            for k in range(0, len(stubs) - 1, 2):
                u, v = min(stubs[k], stubs[k + 1]), max(stubs[k], stubs[k + 1])
                if u != v and (u, v) not in edges:
                    edges.add((u, v))
                    order.append((u, v))
                else:
                    kept[u] = kept.get(u, 0) + 1
                    kept[v] = kept.get(v, 0) + 1
            keys = list(kept)
            suitable = not keys
            # NetworkX's _suitable, quirk included: swapping s1 and s2 rebinds s1 for the rest of
            # the inner loop, so after the first larger s1 it walks on from the smaller vertex.
            for x in keys:
                s1 = x
                for y in keys:
                    if s1 == y:
                        break
                    a, b = min(s1, y), max(s1, y)
                    s1 = a
                    if (a, b) not in edges:
                        suitable = True
                        break
                if suitable:
                    break
            if not suitable:
                failed = True
                break
            stubs = [v for v in keys for _ in range(kept[v])]
        if not failed:
            return R(n, order, False)


def random_bipartite(a, b, p, rng, directed=False):
    """NetworkX bipartite.random_graph(a, b, p, directed=): left 0..<a, right a..<a + b; one
    Batagelj–Brandes sweep over the pairs (v, w), v then w, left → right; directed, a second sweep
    right → left. p = 1: every left–right pair (both arcs when directed), no draws."""
    require(isinstance(a, int) and a >= 0, f"leftCount {a} is negative")
    require(isinstance(b, int) and b >= 0, f"rightCount {b} is negative")
    _probability(p, "edgeProbability")
    pairs = [(v, a + w) for v in range(a) for w in range(b)]
    if p >= 1.0:
        return R(a + b, pairs + ([(y, x) for x, y in pairs] if directed else []), directed)
    if p <= 0.0:
        return R(a + b, [], directed)
    lp = math.log(1.0 - p)
    if lp == 0.0:
        return R(a + b, [], directed)
    edges = []

    def sweep(emit):
        v, w = 0, -1
        while v < a:
            skip = math.log(1.0 - rng.uniform01()) / lp
            if not skip < a * b:
                return
            w = w + 1 + int(skip)
            while w >= b and v < a:
                w -= b
                v += 1
            if v < a:
                emit(v, a + w)

    sweep(lambda v, w: edges.append((v, w)))
    if directed:
        sweep(lambda v, w: edges.append((w, v)))
    return R(a + b, edges, directed)


def sbm(sizes, P, rng, directed=False):
    """NetworkX stochastic_block_model(sparse=True), blocks of consecutive vertices iterated in
    ascending order."""
    B = len(sizes)
    for s in sizes:
        require(isinstance(s, int) and s >= 0, f"block size {s} is negative")
    require(len(P) == B and all(len(row) == B for row in P), "edgeProbabilities is not blockSizes.count square")
    for row in P:
        for x in row:
            _probability(x, "edge probability")
    if not directed:
        for i in range(B):
            for j in range(B):
                require(P[i][j] == P[j][i], "edgeProbabilities is not symmetric")
    starts = [sum(sizes[:i]) for i in range(B + 1)]
    parts = [list(range(starts[i], starts[i + 1])) for i in range(B)]
    blocks = itertools.product(range(B), range(B)) if directed else itertools.combinations_with_replacement(range(B), 2)
    edges = []
    for i, j in blocks:
        if i == j:
            pairs = itertools.permutations(parts[i], 2) if directed else itertools.combinations(parts[i], 2)
        else:
            pairs = itertools.product(parts[i], parts[j])
        p = P[i][j]
        if p == 1.0:
            edges.extend(pairs)
        elif p > 0.0:
            lp = math.log(1.0 - p)
            if lp == 0.0:
                continue
            while True:
                u = rng.uniform01()
                if u == 0.0:  # log(0): NetworkX raises; the block pair ends
                    break
                skip = math.floor(math.log(u) / lp)
                next(itertools.islice(pairs, skip, skip), None)
                e = next(pairs, None)
                if e is None:
                    break
                edges.append(e)
    return R(sum(sizes), edges, directed)


def sbm_sets_ascending(sizes):
    starts = [sum(sizes[:i]) for i in range(len(sizes) + 1)]
    return all(list(set(range(starts[i], starts[i + 1]))) == list(range(starts[i], starts[i + 1]))
               for i in range(len(sizes)))


def prufer_decode(code):
    """Tree(pruferSequence:) in Sources/Trees/Prufer.swift: edges in decoding order, (leaf, x)."""
    n = len(code) + 2
    degree = [1] * n
    for x in code:
        degree[x] += 1
    edges = []
    pointer = 0
    while degree[pointer] != 1:
        pointer += 1
    leaf = pointer
    for v in code:
        edges.append((leaf, v))
        degree[leaf] -= 1
        degree[v] -= 1
        if degree[v] == 1 and v < pointer:
            leaf = v
        else:
            pointer += 1
            while degree[pointer] != 1:
                pointer += 1
            leaf = pointer
    edges.append((leaf, n - 1))
    return edges


def random_tree(n, rng):
    """NetworkX random_labeled_tree: n - 2 draws below(n), decoded as a Prüfer sequence."""
    _count(n)
    require(n >= 1, "a Tree has at least one vertex")
    if n == 1:
        return R(1, [], False, code=[], sort=False)
    code = [rng.below(n) for _ in range(n - 2)]
    return R(n, prufer_decode(code), False, code=code, sort=False)


def dag_gnp(n, p, rng):
    g = gnp(n, p, rng)
    return R(n, g.edges, True)  # (u, v) with u < v: lower index -> higher


def dag_gnm(n, m, rng):
    g = gnm(n, m, rng)
    return R(n, g.edges, True)


# ---------------------------------------------------------------- NetworkX on our stream

def nx_same(kind, args, seed, result):
    """Whether NetworkX, run on our stream, gives the same graph; None when it cannot be compared."""
    r = StreamRandom(seed)
    if kind == "gnp":
        n, p, d = args
        H = nx.fast_gnp_random_graph(n, p, seed=r, directed=d)
    elif kind == "dag_gnp":
        n, p = args
        H = nx.fast_gnp_random_graph(n, p, seed=r)
        H = nx.DiGraph([(min(u, v), max(u, v)) for u, v in H.edges()])
        H.add_nodes_from(range(n))
    elif kind in ("gnm", "dag_gnm"):
        n, m, d = (args + (False,)) if kind == "dag_gnm" else args
        N = n * (n - 1) if d else n * (n - 1) // 2
        if 2 * m > N and m != N:
            return None
        H = nx.gnm_random_graph(n, m, seed=r, directed=d)
        if kind == "dag_gnm":
            H2 = nx.DiGraph([(min(u, v), max(u, v)) for u, v in H.edges()])
            H2.add_nodes_from(range(n))
            H = H2
    elif kind == "ba":
        n, m, d = args
        if not ba_set_order_is_ascending(n, m, seed):
            return None
        H = nx.barabasi_albert_graph(n, m, seed=r)
        if d:
            H = nx.DiGraph([(max(u, v), min(u, v)) for u, v in H.edges()])
    elif kind == "ws":
        n, k, p = args
        H = nx.watts_strogatz_graph(n, k, p, seed=r)
    elif kind == "reg":
        n, d = args
        H = nx.random_regular_graph(d, n, seed=r)
    elif kind == "bip":
        a, b, p = args
        if result.directed and p >= 1.0:  # NetworkX returns the undirected K(a, b) there
            H = nx.complete_bipartite_graph(a, b)
        else:
            H = nx.bipartite.random_graph(a, b, p, seed=r, directed=result.directed)
    elif kind == "rgg":
        n, radius, dim = args
        H = nx.random_geometric_graph(n, radius, dim=dim, seed=r)
        pos = nx.get_node_attributes(H, "pos")
        assert [pos[v] for v in range(n)] == result.positions
    elif kind == "sbm":
        sizes, P, d = args
        if not sbm_sets_ascending(sizes):
            return None
        try:
            H = nx.stochastic_block_model(sizes, P, seed=r, directed=d)
        except ValueError:  # log(0); our procedure ends the block pair instead
            return None
    elif kind == "tree":
        (n,) = args
        H = nx.random_labeled_tree(n, seed=r)
    else:
        raise AssertionError(kind)
    if result.directed and not H.is_directed():  # both arcs of every edge
        H = H.to_directed()
    return nx_key(H) == result.key()


def ig_laws(kind, result):
    H = ig.Graph(n=result.n, edges=result.edges, directed=result.directed)
    assert H.is_simple()
    if kind == "tree":
        assert H.is_tree()
        degree = [1] * result.n
        for x in result.code or []:
            degree[x] += 1
        assert result.n == 1 or H.degree() == degree
    if kind.startswith("dag"):
        assert H.is_dag() and all(u < v for u, v in result.edges)


# ---------------------------------------------------------------- rows

ROWS = []
UL = "UndirectedAdjacencyList<Int>"
CSR = "CompressedSparseRow"
DAG = "DirectedAcyclicGraph<AdjacencyList<Int>>"


def fmt_edges(r):
    sep = "→" if r.directed else "–"
    return "[" + ", ".join(f"{u}{sep}{v}" for u, v in r.edges) + "]"


def exact_row(group, case, call, kind, args, seed, fn, show_positions=False):
    rng = Xoshiro256StarStar(seed)
    try:
        r = fn(rng)
    except Trap as t:
        ROWS.append((group, case, call.replace("SEED", str(seed)), f"**trap**: {t}"))
        return
    ig_laws(kind, r)
    same = None if args is None else nx_same(kind, args, seed, r)
    if same is False and kind not in ("ba",):
        raise AssertionError(f"NetworkX differs on {case} seed {seed}")
    text = f"n {r.n}; m {len(r.edges)}"
    if r.code is not None:
        text += f"; code {r.code}"
    text += f"; E {fmt_edges(r)}"
    if show_positions:
        text += "; pos [" + ", ".join("(" + ", ".join(repr(c) for c in p) + ")" for p in r.positions) + "]"
    text += f"; draws {rng.draws}"
    if same:
        text += "; = NetworkX"
    ROWS.append((group, case, call.replace("SEED", str(seed)), text))
    return r


def trap_row(group, case, call, fn):
    try:
        fn(Xoshiro256StarStar(0))
    except Trap as t:
        ROWS.append((group, case, call, f"**trap**: {t}"))
        return
    raise AssertionError(f"{case}: expected a trap")


def stat_row(group, case, call, text):
    ROWS.append((group, case, call, text))


def z_text(total, S, mean, var):
    """Sum over S seeds against expectation mean (per seed) and variance var (per seed)."""
    obs = total / S
    z = (obs - mean) / math.sqrt(var / S) if var > 0 else 0.0
    assert abs(z) <= 4.0, f"z = {z}"
    return f"Σ {total} over seeds 0..<{S} (mean {obs:.4f}; expected {mean:.4f}; |z| {abs(z):.2f} ≤ 4)"


CHI2_999 = {2: 13.816, 5: 20.515, 7: 24.322, 14: 36.123, 15: 37.697, 19: 43.820}


def chi_text(counts, probs, S):
    df = len(probs) - 1
    chi = sum((counts.get(k, 0) - S * p) ** 2 / (S * p) for k, p in probs.items())
    assert set(counts) <= set(probs)
    assert chi <= CHI2_999[df], f"chi2 {chi} > {CHI2_999[df]}"
    return f"{len(probs)} outcomes over seeds 0..<{S}; χ² {chi:.2f} ≤ {CHI2_999[df]} (df {df}, 0.999)"


def build_rows():
    # ---- the generator (public API)
    x = Xoshiro256StarStar(state=[1, 2, 3, 4])
    stat_row("Generator", "xoshiro256** reference vector (rand_xoshiro's test)",
             "Xoshiro256StarStar(state: (1, 2, 3, 4)); next() × 4",
             f"{[x.next() for _ in range(4)]}")
    stat_row("Generator", "the all-zero state never leaves zero", "Xoshiro256StarStar(state: (0, 0, 0, 0))",
             "**trap**: the state must not be all zero")
    for seed in (0, 1, 42, (1 << 64) - 1):
        g = Xoshiro256StarStar(seed)
        stat_row("Generator", f"seed {seed}: SplitMix64 fills the state", f"Xoshiro256StarStar(seed: {seed}); next() × 4",
                 f"{[g.next() for _ in range(4)]}")
    g = Xoshiro256StarStar(5)
    first = [g.next() for _ in range(3)]
    stat_row("Generator", "a copy replays the stream (value semantics)",
             "var a = Xoshiro256StarStar(seed: 5); var b = a; a.next() × 3; b.next() × 3",
             f"both {first}")
    stat_row("Generator", "works with any RandomNumberGenerator API (values not pinned)",
             "Int.random(in: 1...6, using: &g)", "in 1...6; not compared: the standard library's algorithm is not ours to pin")

    # ---- G(n, p)
    for n, p, seeds in ((10, 0.3, (0, 1, 42)), (6, 0.5, (0,)), (1, 0.5, (0,)), (0, 0.5, (0,))):
        for s in seeds:
            exact_row("ErdosRenyiGnp", f"G({n}, {p}) undirected", f"{UL}.erdosRenyi(vertexCount: {n}, edgeProbability: {p}, using: &Xoshiro256StarStar(seed: SEED))",
                      "gnp", (n, p, False), s, lambda rng, n=n, p=p: gnp(n, p, rng))
    for s in (0, 1):
        exact_row("ErdosRenyiGnp", "G(6, 0.3) directed: lower→higher pass, then higher→lower",
                  f"{CSR}.erdosRenyi(vertexCount: 6, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: SEED))",
                  "gnp", (6, 0.3, True), s, lambda rng: gnp(6, 0.3, rng, True))
    exact_row("ErdosRenyiGnp", "p = 0: no draws", f"{UL}.erdosRenyi(vertexCount: 5, edgeProbability: 0.0, using: &…)",
              "gnp", (5, 0.0, False), 0, lambda rng: gnp(5, 0.0, rng))
    exact_row("ErdosRenyiGnp", "p = 1: complete, no draws", f"{UL}.erdosRenyi(vertexCount: 4, edgeProbability: 1.0, using: &…)",
              "gnp", (4, 1.0, False), 0, lambda rng: gnp(4, 1.0, rng))
    exact_row("ErdosRenyiGnp", "p = 1 directed", f"{CSR}.erdosRenyi(vertexCount: 3, edgeProbability: 1.0, using: &…)",
              "gnp", (3, 1.0, True), 0, lambda rng: gnp(3, 1.0, rng, True))
    exact_row("ErdosRenyiGnp", "p = 1e-300: 1 − p rounds to 1, empty, no draws",
              f"{UL}.erdosRenyi(vertexCount: 1000, edgeProbability: 1e-300, using: &…)", "gnp", None, 0,
              lambda rng: gnp(1000, 1e-300, rng))
    r = gnp(20000, 1e-12, Xoshiro256StarStar(3))
    stat_row("ErdosRenyiGnp", "a skip past every remaining pair ends the sweep before any Int conversion",
             f"{UL}.erdosRenyi(vertexCount: 20000, edgeProbability: 1e-12, using: &Xoshiro256StarStar(seed: 3))",
             f"n 20000; m {len(r.edges)}; E {fmt_edges(r)}")
    for case, fn in (("negative vertex count", lambda rng: gnp(-1, 0.5, rng)),
                     ("p > 1", lambda rng: gnp(5, 1.5, rng)),
                     ("p < 0", lambda rng: gnp(5, -0.1, rng)),
                     ("p NaN", lambda rng: gnp(5, float("nan"), rng))):
        trap_row("ErdosRenyiGnp", case, f"{UL}.erdosRenyi(…)", fn)
    S = 200
    tot = sum(len(gnp(100, 0.05, Xoshiro256StarStar(s)).edges) for s in range(S))
    N = 4950
    stat_row("ErdosRenyiGnp", "law: E[m] = p·C(n, 2)", "G(100, 0.05) undirected", z_text(tot, S, N * 0.05, N * 0.05 * 0.95))
    tot = sum(len(gnp(100, 0.05, Xoshiro256StarStar(s), True).edges) for s in range(S))
    stat_row("ErdosRenyiGnp", "law: E[m] = p·n(n − 1)", "G(100, 0.05) directed", z_text(tot, S, 2 * N * 0.05, 2 * N * 0.05 * 0.95))
    degs = []
    for s in range(S):
        d = [0] * 100
        for u, v in gnp(100, 0.05, Xoshiro256StarStar(s)).edges:
            d[u] += 1
            d[v] += 1
        degs.extend(d)
    mean = sum(degs) / len(degs)
    var = sum((x - mean) ** 2 for x in degs) / (len(degs) - 1)
    expected = 99 * 0.05 * 0.95
    assert abs(var - expected) / expected < 0.05
    stat_row("ErdosRenyiGnp", "law: degree variance (n − 1)p(1 − p)", "G(100, 0.05), degrees pooled over seeds 0..<200",
             f"variance {var:.4f}; expected {expected:.4f}; within 5%")
    counts = {}
    S2 = 4000
    for s in range(S2):
        e = tuple(gnp(3, 0.3, Xoshiro256StarStar(s)).edges)
        counts[e] = counts.get(e, 0) + 1
    probs = {}
    allp = list(itertools.combinations(range(3), 2))
    for k in range(4):
        for sub in itertools.combinations(allp, k):
            probs[tuple(sub)] = 0.3 ** k * 0.7 ** (3 - k)
    stat_row("ErdosRenyiGnp", "law: each labeled graph on 3 vertices with probability p^m (1 − p)^(3 − m)",
             "G(3, 0.3) undirected", chi_text(counts, probs, S2))

    # ---- G(n, m)
    for n, m, d, seeds in ((10, 8, False, (0, 1, 42)), (6, 12, False, (0,)), (6, 15, False, (0,)),
                           (5, 6, True, (0, 1)), (4, 10, True, (0,)), (0, 0, False, (0,)), (1, 0, False, (0,))):
        rep = CSR if d else UL
        N = n * (n - 1) if d else n * (n - 1) // 2
        note = "" if 2 * m <= N else f" (2m > N = {N}: the loop picks the {N - m} pairs left out)"
        for s in seeds:
            exact_row("ErdosRenyiGnm", f"G({n}, {m}) {'directed' if d else 'undirected'}{note}",
                      f"{rep}.erdosRenyi(vertexCount: {n}, edgeCount: {m}, using: &Xoshiro256StarStar(seed: SEED))",
                      "gnm", (n, m, d), s, lambda rng, n=n, m=m, d=d: gnm(n, m, rng, d))
    for case, rep, fn in (("m > N", UL, lambda rng: gnm(4, 7, rng)),
                          ("m > N directed", CSR, lambda rng: gnm(3, 7, rng, True)),
                          ("negative m", UL, lambda rng: gnm(4, -1, rng)),
                          ("n = 1, m = 1", UL, lambda rng: gnm(1, 1, rng))):
        trap_row("ErdosRenyiGnm", case, f"{rep}.erdosRenyi(vertexCount:edgeCount:using:)", fn)
    for (n, m, d, S2) in ((4, 3, False, 4000), (4, 5, False, 1200), (3, 2, True, 3000)):
        counts = {}
        for s in range(S2):
            r = gnm(n, m, Xoshiro256StarStar(s), d)
            assert len(r.edges) == m
            counts[tuple(r.edges)] = counts.get(tuple(r.edges), 0) + 1
        allp = list(itertools.permutations(range(n), 2) if d else itertools.combinations(range(n), 2))
        probs = {tuple(sorted(sub)): 1 / math.comb(len(allp), m) for sub in itertools.combinations(allp, m)}
        stat_row("ErdosRenyiGnm", f"law: uniform over the C(N, m) graphs{' (complement branch)' if 2 * m > len(allp) else ''}",
                 f"G({n}, {m}) {'directed' if d else 'undirected'}", chi_text(counts, probs, S2))

    # ---- Barabási–Albert
    for n, m, seeds in ((10, 1, (0, 1)), (10, 2, (0, 1, 42)), (12, 3, (0,)), (2, 1, (0,))):
        for s in seeds:
            exact_row("BarabasiAlbert", f"n {n}, m {m}: star on 0…{m}, then each new vertex to {m} distinct targets",
                      f"{UL}.barabasiAlbert(vertexCount: {n}, edgesPerVertex: {m}, using: &Xoshiro256StarStar(seed: SEED))",
                      "ba", (n, m, False), s, lambda rng, n=n, m=m: barabasi_albert(n, m, rng))
    exact_row("BarabasiAlbert", "directed: new vertex → older vertex (igraph)",
              f"{CSR}.barabasiAlbert(vertexCount: 8, edgesPerVertex: 2, using: &Xoshiro256StarStar(seed: SEED))",
              "ba", (8, 2, True), 0, lambda rng: barabasi_albert(8, 2, rng, True))
    for case, fn in (("m = 0", lambda rng: barabasi_albert(5, 0, rng)),
                     ("m = n", lambda rng: barabasi_albert(5, 5, rng)),
                     ("n = 1", lambda rng: barabasi_albert(1, 1, rng))):
        trap_row("BarabasiAlbert", case, f"{UL}.barabasiAlbert(…)", fn)
    S = 50
    n, m = 1000, 2
    low = 0
    for s in range(S):
        r = barabasi_albert(n, m, Xoshiro256StarStar(s))
        assert len(r.edges) == m * (n - m)
        d = [0] * n
        for u, v in r.edges:
            d[u] += 1
            d[v] += 1
        assert sum(d) == 2 * m * (n - m) and min(d) >= 1 and min(d[m + 1:]) >= m
        low += sum(1 for x in d if x == m)
    frac = low / (S * n)
    assert abs(frac - 2 / (m + 2)) < 0.02
    stat_row("BarabasiAlbert", "laws: m(n − m) edges, degree sum 2m(n − m), every new vertex has degree ≥ m",
             f"n {n}, m {m}, seeds 0..<{S}", "hold for every seed")
    stat_row("BarabasiAlbert", "law: share of degree-m vertices → 2/(m + 2) (Bollobás et al. 2001)",
             f"n {n}, m {m}, pooled over seeds 0..<{S}", f"{low} of {S * n} ({frac:.4f}); expected 0.5000 ± 0.02")

    # ---- Watts–Strogatz
    for n, k, p, seeds in ((10, 4, 0.0, (0,)), (10, 4, 0.3, (0, 1, 42)), (10, 4, 1.0, (0,)), (8, 2, 0.5, (0,)),
                           (6, 6, 0.5, (0,)), (7, 6, 0.5, (0,)), (5, 0, 0.5, (0,))):
        note = {0.0: "p = 0: the ring lattice (draws still made)", 1.0: "p = 1: every edge rewired where possible"}.get(p, "")
        if k == n:
            note = "k = n: complete, no draws (NetworkX)"
        if k == 0:
            note = "k = 0: no edges, no draws"
        if n == 7 and k == 6:
            note = "k = n − 1: every rewiring hits a full vertex and is skipped"
        for s in seeds:
            exact_row("WattsStrogatz", f"n {n}, k {k}, p {p}" + (f": {note}" if note else ""),
                      f"{UL}.wattsStrogatz(vertexCount: {n}, nearestNeighborCount: {k}, rewiringProbability: {p}, using: &Xoshiro256StarStar(seed: SEED))",
                      "ws", (n, k, p), s, lambda rng, n=n, k=k, p=p: watts_strogatz(n, k, p, rng))
    for case, fn in (("odd k (NetworkX floors it)", lambda rng: watts_strogatz(10, 3, 0.1, rng)),
                     ("k > n", lambda rng: watts_strogatz(4, 6, 0.1, rng)),
                     ("p > 1", lambda rng: watts_strogatz(10, 4, 1.5, rng))):
        trap_row("WattsStrogatz", case, f"{UL}.wattsStrogatz(…)", fn)
    S = 100
    n, k, p = 200, 6, 0.2
    missing = 0
    for s in range(S):
        r = watts_strogatz(n, k, p, Xoshiro256StarStar(s))
        assert len(r.edges) == n * k // 2
        d = [0] * n
        for u, v in r.edges:
            d[u] += 1
            d[v] += 1
        assert min(d) >= k // 2
        E = set(r.edges)
        missing += sum(1 for u in range(n) for j in range(1, k // 2 + 1)
                       if (min(u, (u + j) % n), max(u, (u + j) % n)) not in E)
    total_ring = S * n * k // 2
    frac = missing / total_ring
    assert abs(frac - p) < 0.01
    stat_row("WattsStrogatz", "laws: nk/2 edges for every p, every vertex keeps degree ≥ k/2",
             f"n {n}, k {k}, p {p}, seeds 0..<{S}", "hold for every seed")
    stat_row("WattsStrogatz", "law: share of ring edges gone ≈ p", f"n {n}, k {k}, p {p}, pooled over seeds 0..<{S}",
             f"{missing} of {total_ring} ({frac:.4f}); expected {p} ± 0.01")

    # ---- random geometric
    for n, radius, dim, seeds in ((8, 0.4, 2, (0, 1)), (6, 0.5, 1, (0,)), (5, 0.7, 3, (0,)), (6, 0.0, 2, (0,)),
                                  (5, 2.0, 2, (0,))):
        for s in seeds:
            exact_row("RandomGeometric", f"n {n}, radius {radius}, dimension {dim}",
                      f"{UL}.randomGeometric(vertexCount: {n}, radius: {radius}, dimension: {dim}, using: &Xoshiro256StarStar(seed: SEED))",
                      "rgg", (n, radius, dim), s, lambda rng, n=n, radius=radius, dim=dim: random_geometric(n, radius, rng, dim),
                      show_positions=(n <= 6))
    for case, fn in (("negative radius", lambda rng: random_geometric(5, -0.1, rng)),
                     ("NaN radius", lambda rng: random_geometric(5, float("nan"), rng)),
                     ("dimension 0", lambda rng: random_geometric(5, 0.1, rng, 0))):
        trap_row("RandomGeometric", case, f"{UL}.randomGeometric(…)", fn)
    S = 100
    n, radius = 100, 0.1
    tot = sum(len(random_geometric(n, radius, Xoshiro256StarStar(s)).edges) for s in range(S))
    q = math.pi * radius ** 2 - 8 * radius ** 3 / 3 + radius ** 4 / 2  # P(|X − Y| ≤ r) in the unit square
    pairs = n * (n - 1) // 2
    # Edges are dependent; the variance per seed is bounded loosely by pairs·q·(1 + 2(n − 2)q).
    stat_row("RandomGeometric", "law: E[m] = C(n, 2)(πr² − 8r³/3 + r⁴/2) in the unit square",
             f"n {n}, radius {radius}", z_text(tot, S, pairs * q, pairs * q * (1 + 2 * (n - 2) * q)))

    # ---- stochastic block model
    for sizes, P, d, seeds in (([3, 3], [[0.9, 0.1], [0.1, 0.9]], False, (0, 1)),
                               ([2, 3, 2], [[1.0, 0.0, 0.5], [0.0, 0.5, 0.2], [0.5, 0.2, 0.0]], False, (0,)),
                               ([3, 2], [[0.5, 0.3], [0.1, 0.8]], True, (0,)),
                               ([0, 4], [[0.5, 0.5], [0.5, 0.5]], False, (0,))):
        rep = CSR if d else UL
        for s in seeds:
            exact_row("StochasticBlockModel", f"sizes {sizes}{' directed' if d else ''}",
                      f"{rep}.stochasticBlockModel(blockSizes: {sizes}, edgeProbabilities: {P}, using: &Xoshiro256StarStar(seed: SEED))",
                      "sbm", (sizes, P, d), s, lambda rng, sizes=sizes, P=P, d=d: sbm(sizes, P, rng, d))
    for case, fn in (("asymmetric undirected", lambda rng: sbm([2, 2], [[0.5, 0.1], [0.2, 0.5]], rng)),
                     ("not square", lambda rng: sbm([2, 2], [[0.5, 0.1]], rng)),
                     ("probability > 1", lambda rng: sbm([2], [[1.5]], rng)),
                     ("negative block size", lambda rng: sbm([2, -1], [[0.5, 0.1], [0.1, 0.5]], rng))):
        trap_row("StochasticBlockModel", case, f"{UL}.stochasticBlockModel(…)", fn)
    S = 200
    sizes, P = [30, 20, 50], [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]]
    tot = 0
    within = 0
    for s in range(S):
        r = sbm(sizes, P, Xoshiro256StarStar(s))
        tot += len(r.edges)
    mean = var = 0.0
    starts = [0, 30, 50, 100]
    for i in range(3):
        for j in range(i, 3):
            cnt = sizes[i] * (sizes[i] - 1) // 2 if i == j else sizes[i] * sizes[j]
            mean += cnt * P[i][j]
            var += cnt * P[i][j] * (1 - P[i][j])
    stat_row("StochasticBlockModel", "law: E[m] = Σ pairs(i, j)·p(i, j)", f"sizes {sizes}, P {P}", z_text(tot, S, mean, var))
    r = sbm([5, 5], [[0.0, 1.0], [1.0, 0.0]], Xoshiro256StarStar(0))
    stat_row("StochasticBlockModel", "p = 0 / 1 blocks need no draws: K5,5",
             f"{UL}.stochasticBlockModel(blockSizes: [5, 5], edgeProbabilities: [[0, 1], [1, 0]], using: &…)",
             f"m {len(r.edges)}; equals completeBipartite(leftCount: 5, rightCount: 5)")

    # ---- random trees
    for n, seeds in ((1, (0,)), (2, (0,)), (6, (0, 1, 42)), (10, (0,))):
        for s in seeds:
            exact_row("RandomTree", f"n {n}: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)",
                      f"Tree<Int>.random(vertexCount: {n}, using: &Xoshiro256StarStar(seed: SEED))",
                      "tree", (n,), s, lambda rng, n=n: random_tree(n, rng))
    trap_row("RandomTree", "n = 0: a tree is never empty", "Tree<Int>.random(vertexCount: 0, using: &…)",
             lambda rng: random_tree(0, rng))
    counts = {}
    S2 = 3200
    for s in range(S2):
        r = random_tree(4, Xoshiro256StarStar(s))
        key = tuple(sorted((min(u, v), max(u, v)) for u, v in r.edges))
        counts[key] = counts.get(key, 0) + 1
    probs = {}
    for code in itertools.product(range(4), repeat=2):
        key = tuple(sorted((min(u, v), max(u, v)) for u, v in prufer_decode(list(code))))
        probs[key] = 1 / 16
    assert len(probs) == 16
    stat_row("RandomTree", "law: uniform over the n^(n − 2) labeled trees (Cayley)", "n 4", chi_text(counts, probs, S2))
    for s in range(50):
        r = random_tree(200, Xoshiro256StarStar(s))
        ig_laws("tree", r)
    stat_row("RandomTree", "laws: n − 1 edges, connected, degree(v) = 1 + occurrences of v in the code",
             "n 200, seeds 0..<50", "hold for every seed (igraph is_tree)")

    # ---- random DAGs
    for s in (0, 1):
        exact_row("RandomDAG", "G(8, 0.4) on pairs u < v, oriented u → v (Barak–Erdős); the order 0..<n is topological",
                  f"{DAG}.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: SEED))",
                  "dag_gnp", (8, 0.4), s, lambda rng: dag_gnp(8, 0.4, rng))
    exact_row("RandomDAG", "G(6, 5) on pairs u < v",
              f"{DAG}.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &Xoshiro256StarStar(seed: SEED))",
              "dag_gnm", (6, 5), 0, lambda rng: dag_gnm(6, 5, rng))
    trap_row("RandomDAG", "m > C(n, 2)", f"{DAG}.erdosRenyi(vertexCount: 4, edgeCount: 7, using: &…)",
             lambda rng: dag_gnm(4, 7, rng))
    S = 200
    tot = sum(len(dag_gnp(60, 0.1, Xoshiro256StarStar(s)).edges) for s in range(S))
    N = 60 * 59 // 2
    stat_row("RandomDAG", "law: E[m] = p·C(n, 2); topologicalOrder == 0..<n", "G(60, 0.1)", z_text(tot, S, N * 0.1, N * 0.1 * 0.9))

    # ---- rows added after the review, numbered after the first 108 so those keep their IDs
    # Directed forms of the symmetric families: both arcs of every edge.
    exact_row("WattsStrogatz", "directed: both arcs of every edge, the undirected draws",
              f"{CSR}.wattsStrogatz(vertexCount: 8, nearestNeighborCount: 2, rewiringProbability: 0.5, using: &Xoshiro256StarStar(seed: SEED))",
              "ws", (8, 2, 0.5), 0, lambda rng: watts_strogatz(8, 2, 0.5, rng, True))
    exact_row("RandomGeometric", "directed: both arcs of every edge, the undirected draws",
              f"{CSR}.randomGeometric(vertexCount: 6, radius: 0.5, dimension: 2, using: &Xoshiro256StarStar(seed: SEED))",
              "rgg", (6, 0.5, 2), 0, lambda rng: random_geometric(6, 0.5, rng, 2, True), show_positions=True)
    # The grid's paths: cells, all pairs when 3^d > n, and r = 0 sized as a tiny radius.
    exact_row("RandomGeometric", "n 30, radius 0.15, dimension 2: the grid of 5 × 5 cells",
              f"{UL}.randomGeometric(vertexCount: 30, radius: 0.15, dimension: 2, using: &Xoshiro256StarStar(seed: SEED))",
              "rgg", (30, 0.15, 2), 0, lambda rng: random_geometric(30, 0.15, rng, 2))
    exact_row("RandomGeometric", "n 12, radius 0.6, dimension 3: 3^d > n, every pair checked",
              f"{UL}.randomGeometric(vertexCount: 12, radius: 0.6, dimension: 3, using: &Xoshiro256StarStar(seed: SEED))",
              "rgg", (12, 0.6, 3), 0, lambda rng: random_geometric(12, 0.6, rng, 3))
    exact_row("RandomGeometric", "radius 0: only coincident points, on the grid sized as for a tiny radius",
              f"{UL}.randomGeometric(vertexCount: 2000, radius: 0.0, dimension: 2, using: &Xoshiro256StarStar(seed: SEED))",
              "rgg", (2000, 0.0, 2), 0, lambda rng: random_geometric(2000, 0.0, rng, 2))

    # ---- random regular graphs
    for n, d, seeds in ((8, 3, (0, 1)), (10, 4, (0,)), (4, 2, (42,)), (7, 6, (0,)), (6, 0, (0,))):
        note = {0: "d = 0: no edges, no draws", n - 1: "d = n − 1: the complete graph, after any retries"}.get(d, "")
        for s in seeds:
            exact_row("RandomRegular", f"n {n}, d {d}" + (f": {note}" if note else ""),
                      f"{UL}.randomRegular(vertexCount: {n}, degree: {d}, using: &Xoshiro256StarStar(seed: SEED))",
                      "reg", (n, d), s, lambda rng, n=n, d=d: random_regular(n, d, rng))
    exact_row("RandomRegular", "directed: both arcs of every edge, the undirected draws",
              f"{CSR}.randomRegular(vertexCount: 6, degree: 2, using: &Xoshiro256StarStar(seed: SEED))",
              "reg", (6, 2), 0, lambda rng: random_regular(6, 2, rng, True))
    for case, fn in (("d = n", lambda rng: random_regular(5, 5, rng)),
                     ("negative d", lambda rng: random_regular(5, -1, rng)),
                     ("n·d odd", lambda rng: random_regular(5, 3, rng)),
                     ("negative vertex count", lambda rng: random_regular(-1, 0, rng))):
        trap_row("RandomRegular", case, f"{UL}.randomRegular(…)", fn)
    S = 50
    for s in range(S):
        r = random_regular(100, 3, Xoshiro256StarStar(s))
        d = [0] * 100
        for u, v in r.edges:
            d[u] += 1
            d[v] += 1
        assert len(r.edges) == 150 and d == [3] * 100
    stat_row("RandomRegular", "laws: nd/2 edges, every vertex of degree d, simple", "n 100, d 3, seeds 0..<50",
             "hold for every seed (igraph is_simple)")
    counts = {}
    S2 = 3000
    for s in range(S2):
        e = tuple(random_regular(4, 2, Xoshiro256StarStar(s)).edges)
        counts[e] = counts.get(e, 0) + 1
    # The procedure commutes with relabeling (the shuffle is uniform), so it is uniform over each
    # isomorphism class; every 2-regular graph on 4 vertices is a 4-cycle.
    probs = {((0, 1), (0, 2), (1, 3), (2, 3)): 1 / 3, ((0, 1), (0, 3), (1, 2), (2, 3)): 1 / 3,
             ((0, 2), (0, 3), (1, 2), (1, 3)): 1 / 3}
    stat_row("RandomRegular", "law: uniform over the 3 labeled 4-cycles (one isomorphism class)", "n 4, d 2",
             chi_text(counts, probs, S2))

    # ---- random bipartite graphs
    for a, b, p, seeds in ((4, 5, 0.4, (0, 1)), (3, 3, 0.5, (42,)), (0, 4, 0.5, (0,)), (3, 0, 0.5, (0,))):
        for s in seeds:
            exact_row("RandomBipartite", f"G({a}, {b}, {p}): left 0..<{a}, right {a}..<{a + b}",
                      f"{UL}.randomBipartite(leftCount: {a}, rightCount: {b}, edgeProbability: {p}, using: &Xoshiro256StarStar(seed: SEED))",
                      "bip", (a, b, p), s, lambda rng, a=a, b=b, p=p: random_bipartite(a, b, p, rng))
    exact_row("RandomBipartite", "p = 0: no edges, no draws",
              f"{UL}.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 0.0, using: &…)",
              "bip", (2, 3, 0.0), 0, lambda rng: random_bipartite(2, 3, 0.0, rng))
    exact_row("RandomBipartite", "p = 1: complete bipartite, no draws",
              f"{UL}.randomBipartite(leftCount: 2, rightCount: 3, edgeProbability: 1.0, using: &…)",
              "bip", (2, 3, 1.0), 0, lambda rng: random_bipartite(2, 3, 1.0, rng))
    for s in (0, 1):
        exact_row("RandomBipartite", "directed: a left → right sweep, then a right → left sweep",
                  f"{CSR}.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 0.3, using: &Xoshiro256StarStar(seed: SEED))",
                  "bip", (3, 4, 0.3), s, lambda rng: random_bipartite(3, 4, 0.3, rng, True))
    for case, fn in (("negative left count", lambda rng: random_bipartite(-1, 3, 0.5, rng)),
                     ("negative right count", lambda rng: random_bipartite(3, -1, 0.5, rng)),
                     ("p > 1", lambda rng: random_bipartite(3, 3, 1.5, rng)),
                     ("p NaN", lambda rng: random_bipartite(3, 3, float("nan"), rng))):
        trap_row("RandomBipartite", case, f"{UL}.randomBipartite(…)", fn)
    S = 200
    tot = sum(len(random_bipartite(30, 20, 0.1, Xoshiro256StarStar(s)).edges) for s in range(S))
    stat_row("RandomBipartite", "law: E[m] = a·b·p", "G(30, 20, 0.1) undirected", z_text(tot, S, 600 * 0.1, 600 * 0.1 * 0.9))
    tot = sum(len(random_bipartite(30, 20, 0.1, Xoshiro256StarStar(s), True).edges) for s in range(S))
    stat_row("RandomBipartite", "law: E[m] = 2·a·b·p", "G(30, 20, 0.1) directed", z_text(tot, S, 1200 * 0.1, 1200 * 0.1 * 0.9))

    # ---- rows added after the mutation pass, numbered after RG-141 so those keep their IDs
    exact_row("WattsStrogatz", "n 4, k 2, p 0.8: a vertex rewired away from loses degree, so it is not full",
              f"{UL}.wattsStrogatz(vertexCount: 4, nearestNeighborCount: 2, rewiringProbability: 0.8, using: &Xoshiro256StarStar(seed: SEED))",
              "ws", (4, 2, 0.8), 0, lambda rng: watts_strogatz(4, 2, 0.8, rng))
    exact_row("RandomRegular", "n 7, d 4: the suitability check's quirk decides whether a round restarts",
              f"{UL}.randomRegular(vertexCount: 7, degree: 4, using: &Xoshiro256StarStar(seed: SEED))",
              "reg", (7, 4), 3, lambda rng: random_regular(7, 4, rng))
    exact_row("BarabasiAlbert", "directed, m 17: more than 16 targets, sorted by the full sort",
              f"{CSR}.barabasiAlbert(vertexCount: 20, edgesPerVertex: 17, using: &Xoshiro256StarStar(seed: SEED))",
              "ba", (20, 17, True), 0, lambda rng: barabasi_albert(20, 17, rng, True))
    exact_row("RandomGeometric", "n 5, radius 0.1, dimension 70: 2^d and 3^d overflow Int, every pair checked",
              f"{UL}.randomGeometric(vertexCount: 5, radius: 0.1, dimension: 70, using: &Xoshiro256StarStar(seed: SEED))",
              "rgg", (5, 0.1, 70), 0, lambda rng: random_geometric(5, 0.1, rng, 70))
    trap_row("WattsStrogatz", "k > n = 0", f"{UL}.wattsStrogatz(…)", lambda rng: watts_strogatz(0, 2, 0.5, rng))
    trap_row("RandomGeometric", "dimension 0 with radius ≥ 1/2 (every pair checked)", f"{UL}.randomGeometric(…)",
             lambda rng: random_geometric(3, 0.6, rng, 0))
    trap_row("RandomRegular", "d = n with n·d even", f"{UL}.randomRegular(…)", lambda rng: random_regular(4, 4, rng))
    trap_row("StochasticBlockModel", "negative block size after a block of 1", f"{UL}.stochasticBlockModel(…)",
             lambda rng: sbm([1, -1], [[0.5, 0.5], [0.5, 0.5]], rng))
    trap_row("StochasticBlockModel", "more rows than blocks", f"{UL}.stochasticBlockModel(…)",
             lambda rng: sbm([2, 2], [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]], rng))
    trap_row("StochasticBlockModel", "longer rows than blocks", f"{UL}.stochasticBlockModel(…)",
             lambda rng: sbm([2, 2], [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]], rng))


HEADER = [
    "# RandomGraphs: case catalog",
    "",
    "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0",
    "python3 Tests/Catalogs/RandomGraphs/ref.py`; `--write` regenerates this file, `--stress` re-checks the",
    "NetworkX equivalences over many seeds). `ref.py` ports the pinned procedures of `api.md` and the",
    "generator; igraph checks simplicity, `is_tree` and `is_dag` on every exact row.",
    "",
    "Conventions:",
    "",
    "* `using: &Xoshiro256StarStar(seed: s)` stands for `var g = Xoshiro256StarStar(seed: s)` and `using: &g`.",
    "  `using: &…` rows make no draws, so any generator gives them.",
    "* `E [...]` is `edges` in order. Every factory but `Tree.random` emits sorted edges: undirected",
    "  `UndirectedEdge(u, v)` with `u < v` in lexicographic order, directed edges in row-major order.",
    "  `Tree.random` keeps `Tree(pruferSequence:)`'s order: edge k joins the k-th leaf removed to the k-th",
    "  code element. `pos` lists positions as shortest round-trip doubles (Python `repr`, Swift `description`),",
    "  so they compare exactly.",
    "* `draws` is how many `next()` calls the factory made: a later draw from the same generator continues",
    "  from there, so the count is part of the pinned procedure. A test checks it with `Equatable`: the",
    "  generator equals a fresh one with the same seed advanced `draws` times.",
    "* `= NetworkX` marks rows that NetworkX 3.7 reproduces edge for edge when it runs on the same stream",
    "  (`StreamRandom` in `ref.py`). Barabási–Albert rows match when CPython's set iteration happens to be",
    "  ascending; G(n, m) rows when 2m ≤ N.",
    "* Statistical rows give the exact aggregate over the listed seeds, which the Swift suite asserts",
    "  exactly, and the law it satisfies, which a reimplementation must also satisfy.",
    "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).",
    "",
    "| ID | Group | Case | Call | Expected |",
    "|---|---|---|---|---|",
]


def render():
    lines = list(HEADER)
    for i, (group, case, call, expected) in enumerate(ROWS, 1):
        lines.append(f"| RG-{i:03d} | {group} | {case} | `{call}` | {expected} |")
    return "\n".join(lines) + "\n"


def stress():
    checked = 0
    for s in range(300):
        for n in (2, 5, 13, 40):
            for p in (0.05, 0.3, 0.7):
                for d in (False, True):
                    assert nx_same("gnp", (n, p, d), s, gnp(n, p, Xoshiro256StarStar(s), d)); checked += 1
                N = n * (n - 1) // 2
                m = int(p * N)
                for d in (False, True):
                    mm = m * (2 if d else 1)
                    res = nx_same("gnm", (n, mm, d), s, gnm(n, mm, Xoshiro256StarStar(s), d))
                    assert res in (True, None); checked += res is True
            for k in (2, 4):
                if k < n:
                    assert nx_same("ws", (n, k, 0.3), s, watts_strogatz(n, k, 0.3, Xoshiro256StarStar(s))); checked += 1
        if s < 100:
            for n in (2, 10, 30):
                assert nx_same("rgg", (n, 0.3, 2), s, random_geometric(n, 0.3, Xoshiro256StarStar(s))); checked += 1
                assert nx_same("tree", (n,), s, random_tree(n, Xoshiro256StarStar(s))); checked += 1
            assert nx_same("ba", (30, 1, False), s, barabasi_albert(30, 1, Xoshiro256StarStar(s))); checked += 1
            res = nx_same("ba", (30, 3, False), s, barabasi_albert(30, 3, Xoshiro256StarStar(s)))
            assert res in (True, None); checked += res is True
            # our port of NetworkX's order reproduces NetworkX exactly
            r = barabasi_albert(30, 3, Xoshiro256StarStar(s), networkx_order=True)
            assert nx_key(nx.barabasi_albert_graph(30, 3, seed=StreamRandom(s))) == r.key(); checked += 1
            for n, d in ((10, 3), (13, 4), (30, 2)):
                assert nx_same("reg", (n, d), s, random_regular(n, d, Xoshiro256StarStar(s))); checked += 1
            for a, b, p in ((5, 7, 0.3), (12, 3, 0.6)):
                for d in (False, True):
                    assert nx_same("bip", (a, b, p), s, random_bipartite(a, b, p, Xoshiro256StarStar(s), d)); checked += 1
            for sizes, P, d in (([4, 3], [[0.5, 0.2], [0.2, 0.7]], False), ([5, 2, 3], [[0.3, 0.1, 0.0], [0.4, 1.0, 0.2], [0.0, 0.2, 0.6]], True)):
                res = nx_same("sbm", (sizes, P, d), s, sbm(sizes, P, Xoshiro256StarStar(s), d))
                assert res in (True, None); checked += res is True
    return checked


def main():
    check_vectors()
    build_rows()
    text = render()
    path = os.path.join(HERE, "cases.md")
    if "--write" in sys.argv:
        open(path, "w").write(text)
        print(f"wrote {len(ROWS)} rows to cases.md")
    else:
        current = open(path).read() if os.path.exists(path) else ""
        if current != text:
            print("cases.md differs from the model (run with --write)")
            sys.exit(1)
        print(f"cases.md: {len(ROWS)} rows agree with the model and NetworkX on the same stream")
    if "--stress" in sys.argv:
        print(f"stress: {stress()} generated graphs equal NetworkX's on the same stream")


if __name__ == "__main__":
    main()
