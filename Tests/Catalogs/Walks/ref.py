"""Reference checks for the Walks catalog (cases.md).

Run: cd <this dir> && uv run --quiet --no-project --with networkx==3.7 python3 ref.py

A Python model of the proposed Swift types (vertices + edge positions), checked against
NetworkX 3.7 where NetworkX has an answer, and against brute force where it does not.
Every check prints its case ID; any failure raises.
"""

import itertools
import random

import networkx as nx

FAILS = []


def check(case, cond, detail=""):
    print(("ok   " if cond else "FAIL ") + case + ("  " + detail if detail else ""))
    if not cond:
        FAILS.append(case)


# ---------------------------------------------------------------- model
# A graph is a list of edges; an edge's position is its index. Directed edges are (source, target),
# undirected ones (u, v) with no order.


def vertices_of(edges, extra=()):
    vs = []
    for v in list(extra) + [x for e in edges for x in e]:
        if v not in vs:
            vs.append(v)
    return vs


def is_walk(edges, vs, es, directed, vertex_set=None):
    """Walk(vertices:edges:in:) != nil."""
    vset = set(vertex_set if vertex_set is not None else vertices_of(edges))
    if len(vs) == 0 or len(vs) != len(es) + 1:
        return False
    if any(v not in vset for v in vs):
        return False
    for i, e in enumerate(es):
        a, b = edges[e]
        if directed:
            if (a, b) != (vs[i], vs[i + 1]):
                return False
        else:
            if {a, b} != {vs[i], vs[i + 1]} or (a == b) != (vs[i] == vs[i + 1]):
                return False
    return True


def is_trail(vs, es):
    return len(set(es)) == len(es)


def is_path(vs, es):
    return len(set(vs)) == len(vs)


def is_circuit_storage(vs, es):
    """Circuit storage: n vertices, n edges, edge i from vs[i] to vs[(i+1) % n]; distinct edges."""
    return len(vs) >= 1 and len(vs) == len(es) and len(set(es)) == len(es)


def is_cycle_storage(vs, es):
    return is_circuit_storage(vs, es) and len(set(vs)) == len(vs)


def closed_walk_to_storage(vs, es):
    """Circuit(walk): drop the repeated closing vertex."""
    assert vs[0] == vs[-1] and len(es) >= 1
    return vs[:-1], es


def storage_to_closed_walk(vs, es):
    """Walk(circuit): repeat the first vertex at the end."""
    return vs + [vs[0]], es


def is_closed_walk_in(edges, vs, es, directed, vertex_set=None):
    w, f = storage_to_closed_walk(vs, es)
    return is_walk(edges, w, f, directed, vertex_set)


def rotate(vs, es, k):
    return vs[k:] + vs[:k], es[k:] + es[:k]


def rot_equal(a, b):
    """Circuit/Cycle ==: equal up to rotation of the (vertex, edge) steps."""
    (va, ea), (vb, eb) = a, b
    if len(va) != len(vb):
        return False
    n = len(va)
    # Edges are distinct in a circuit, so at most one offset can match: linear time.
    cands = [k for k in range(n) if ea[k] == eb[0]]
    assert len(cands) <= 1
    return any(rotate(va, ea, k) == (vb, eb) for k in cands)


def rot_equal_bruteforce(a, b):
    (va, ea), (vb, eb) = a, b
    return len(va) == len(vb) and any(rotate(va, ea, k) == (vb, eb) for k in range(len(va)))


MASK = (1 << 64) - 1


def step_hash(v, e):
    return hash(("step", v, e)) & MASK


def comm_hash(vs, es):
    """Circuit/Cycle hash(into:): count, then the wrapping sum of per-step hashes."""
    s = 0
    for v, e in zip(vs, es):
        s = (s + step_hash(v, e)) & MASK
    return hash((len(vs), s))


def reverse_walk(vs, es):
    return vs[::-1], es[::-1]


def reverse_cycle(vs, es):
    """Cycle.reversed(): v0 -e0- v1 ... v(n-1) -e(n-1)- v0 traversed backward from v0."""
    return [vs[0]] + vs[1:][::-1], es[::-1]


def weight(es, w):
    total = 0
    for e in es:
        total = total + w[e]
    return total


def pick_edges(edges, vs, directed, unused_only, vertex_set=None):
    """Walk(_ vertices:in:) / Trail(_ vertices:in:): the first (unused) edge in out/incident order."""
    vset = set(vertex_set if vertex_set is not None else vertices_of(edges))
    if not vs or any(v not in vset for v in vs):
        return None
    used = set()
    es = []
    for a, b in zip(vs, vs[1:]):
        found = None
        for p, (x, y) in enumerate(edges):  # out/incident order = position order in the reference graphs
            ok = (x, y) == (a, b) if directed else ({x, y} == {a, b} and (x == y) == (a == b))
            if ok and not (unused_only and p in used):
                found = p
                break
        if found is None:
            return None
        used.add(found)
        es.append(found)
    return es


def all_edge_choices(edges, vs, directed):
    options = []
    for a, b in zip(vs, vs[1:]):
        opts = [p for p, (x, y) in enumerate(edges)
                if ((x, y) == (a, b) if directed else ({x, y} == {a, b} and (x == y) == (a == b)))]
        options.append(opts)
    return itertools.product(*options)


# ---------------------------------------------------------------- WK-1xx construction / validation

# Directed fixture D4: JGraphT GraphWalkTest / LEMON path_test: 0→1, 1→2, 2→3, 3→0 at positions 0..3.
D4 = [(0, 1), (1, 2), (2, 3), (3, 0)]
check("WK-101", is_walk(D4, [0, 1, 2, 3], [0, 1, 2], True))
check("WK-102", not is_walk(D4, [0, 1, 3, 2], [0, 1, 2], True), "JGraphT testInvalidPath4 shape")
check("WK-103", not is_walk(D4, [0, 1, 2], [0, 2], True), "JGraphT testInvalidPath5: skips 1→2")
# LEMON's inconsistent path a4, a2, a1 = positions 3, 1, 0 (source n4 = 3, target n2 = 1)
check("WK-104", all(not is_walk(D4, vs, [3, 1, 0], True) for vs in itertools.product(range(4), repeat=4)),
      "no vertex list makes LEMON's [a4, a2, a1] a walk")
check("WK-105", is_walk(D4, [3, 0, 1, 2], [3, 0, 1], True), "LEMON addFront a3? no: a4,a1,a2 = [3,0,1]")
check("WK-106", is_walk(D4, [2], [], True) and not is_walk(D4, [9], [], True),
      "trivial walk needs its vertex in the graph")
check("WK-107", not is_walk(D4, [], [], True), "no empty walk")
check("WK-108", not is_walk(D4, [0, 1], [0, 1], True), "count mismatch is not a walk of g")
check("WK-109", pick_edges(D4, [0, 1, 2, 3, 0, 1], True, False) == [0, 1, 2, 3, 0])
check("WK-110", pick_edges(D4, [0, 2], True, False) is None)
# JGraphT testInvalidPath3: [0, 0] in a simple graph without a loop
check("WK-111", pick_edges([(0, 1)], [0, 0], False, False) is None)

# ---------------------------------------------------------------- NetworkX is_path agreement (walks)
G = [(1, 2), (2, 3), (1, 2), (3, 4)]  # NetworkX test_ispath, parallel 1-2 in the multigraphs
for directed, name, cls in [(False, "Graph", nx.Graph), (True, "DiGraph", nx.DiGraph),
                            (False, "MultiGraph", nx.MultiGraph), (True, "MultiDiGraph", nx.MultiDiGraph)]:
    H = cls()
    H.add_edges_from(G)
    for vs, case in [([1, 2, 3, 4], "WK-121"), ([1, 2, 4, 3], "WK-122"), ([1, 2, 3, 4, 5], "WK-123"),
                     ([3, 2, 1], "WK-124"), ([1, 2, 1, 2, 3], "WK-125")]:
        ours = pick_edges(G, vs, directed, False) is not None
        check(f"{case} {name} {vs}", ours == nx.is_path(H, vs), f"is_path={nx.is_path(H, vs)}")
# The disagreements: NetworkX accepts a one-node list naming no node, and the empty list.
H = nx.Graph([(1, 2)])
check("WK-126", nx.is_path(H, [99]) is True and pick_edges([(1, 2)], [99], False, False) is None,
      "NetworkX is_path(G, [99]) is True; ours is nil")
check("WK-127", nx.is_path(H, []) is True and pick_edges([(1, 2)], [], False, False) is None,
      "NetworkX is_path(G, []) is True; ours is nil")
check("WK-128", nx.is_path(nx.MultiDiGraph([(0, 0)]), [0, 0, 0]) and pick_edges([(0, 0)], [0, 0, 0], True, False) == [0, 0],
      "loop walked twice is a walk")
check("WK-129", pick_edges([(0, 0)], [0, 0, 0], True, True) is None, "but not a trail")

# ---------------------------------------------------------------- WK-2xx invariants
check("WK-201", is_trail([0, 1, 2, 3, 2, 3, 4], [0, 1, 2, 3, 4, 5]) is True, "distinct positions")
K5 = [(a, b) for a, b in itertools.combinations(range(5), 2)]
pos = {frozenset(e): p for p, e in enumerate(K5)}
jg = [0, 1, 2, 3, 2, 3, 4]  # JGraphT testNonSimplePath on K5
jg_es = [pos[frozenset((a, b))] for a, b in zip(jg, jg[1:])]
check("WK-202", is_walk(K5, jg, jg_es, False) and not is_trail(jg, jg_es) and not is_path(jg, jg_es),
      f"JGraphT non-simple path on K5: edges {jg_es}, edge {2,3} used three times")
check("WK-203", jg_es == [0, 4, 7, 7, 7, 9], f"positions of K5 edges in combinations order: {jg_es}")
check("WK-204", is_trail([0, 1, 2, 0, 3], [0, 1, 2, 3]) and not is_path([0, 1, 2, 0, 3], [0, 1, 2, 3]),
      "bowtie trail revisits 0")
check("WK-205", is_cycle_storage([0], [5]) and is_circuit_storage([0], [5]), "self-loop is a 1-cycle")
check("WK-206", is_cycle_storage([0, 1], [0, 1]) and not is_cycle_storage([0, 1], [0, 0]),
      "digon needs two distinct edges")
check("WK-207", not is_circuit_storage([], []), "no empty circuit")
check("WK-208", is_circuit_storage([0, 1, 2, 0, 3, 4], [0, 1, 2, 3, 4, 5]) and
      not is_cycle_storage([0, 1, 2, 0, 3, 4], [0, 1, 2, 3, 4, 5]), "figure eight")

# A path's edges are distinct in any graph (so Trail(path) never fails), checked by brute force.
rng = random.Random(7)
for trial in range(300):
    n = rng.randint(1, 4)
    directed = rng.random() < 0.5
    E = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(0, 7))]
    for length in range(0, 4):
        for vs in itertools.product(range(n), repeat=length + 1):
            if len(set(vs)) != len(vs):
                continue
            for es in all_edge_choices(E, list(vs), directed):
                assert is_walk(E, list(vs), list(es), directed, range(n))
                assert len(set(es)) == len(es)
check("WK-209", True, "300 random multigraphs: every path has distinct edges")

# A closed walk with distinct vertices (cycle storage) of length >= 3 has distinct edges; length 2
# needs the check (undirected digon on one edge), length 1 trivially distinct.
bad2 = 0
for trial in range(300):
    n = rng.randint(1, 4)
    directed = rng.random() < 0.5
    E = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(0, 7))]
    for length in range(1, 5):
        for vs in itertools.permutations(range(n), length):
            w = list(vs) + [vs[0]]
            for es in all_edge_choices(E, w, directed):
                if len(set(es)) != len(es):
                    assert length == 2 and not directed, (E, vs, es)
                    bad2 += 1
check("WK-210", bad2 > 0, f"only undirected 2-cycles can repeat an edge ({bad2} found)")

# ---------------------------------------------------------------- WK-5xx multigraph
M = [(0, 1), (0, 1), (1, 0)]  # directed: two parallel 0→1 at 0 and 1, and 1→0 at 2
check("WK-501", pick_edges(M, [0, 1], True, False) == [0], "first parallel edge in out-edge order")
check("WK-502", is_walk(M, [0, 1], [1], True), "second parallel edge is a different walk")
check("WK-503", pick_edges(M, [0, 1, 0, 1], True, False) == [0, 2, 0])
check("WK-504", pick_edges(M, [0, 1, 0, 1], True, True) == [0, 2, 1], "trail picks the unused copy")
check("WK-505", pick_edges(M, [0, 1, 0, 1, 0, 1], True, True) is None, "only two copies of 0→1")
check("WK-506", is_cycle_storage([0, 1], [0, 2]) and is_closed_walk_in(M, [0, 1], [0, 2], True))
check("WK-507", is_closed_walk_in(M, [0, 1], [1, 2], True) and not rot_equal(([0, 1], [0, 2]), ([0, 1], [1, 2])),
      "same vertices, different parallel edge: unequal cycles")
L = [(0, 0), (0, 0)]
check("WK-508", pick_edges(L, [0, 0, 0], True, True) == [0, 1] and pick_edges(L, [0, 0, 0], False, True) == [0, 1])
check("WK-509", is_circuit_storage([0, 0], [0, 1]) and not is_cycle_storage([0, 0], [0, 1]),
      "two loops at one vertex: a circuit, not a cycle")

# Greedy first-unused picking is exact for trails (exists iff greedy succeeds), by brute force.
for trial in range(400):
    n = rng.randint(1, 3)
    directed = rng.random() < 0.5
    E = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(0, 6))]
    for length in range(0, 5):
        for vs in itertools.product(range(n), repeat=length + 1):
            vs = list(vs)
            exists = any(len(set(es)) == len(es) for es in all_edge_choices(E, vs, directed))
            greedy = pick_edges(E, vs, directed, True, range(n))
            assert (greedy is not None) == exists, (E, vs, directed)
            if greedy is not None:
                assert is_walk(E, vs, greedy, directed, range(n)) and len(set(greedy)) == len(greedy)
check("WK-510", True, "400 random multigraphs: first-unused picking finds a trail exactly when one exists")
# ... but plain first picking (Walk) then Trail(walk) can fail when a trail exists:
check("WK-511", pick_edges(M, [0, 1, 0, 1], True, False) == [0, 2, 0] and
      not is_trail(None, [0, 2, 0]) and pick_edges(M, [0, 1, 0, 1], True, True) is not None,
      "Trail(Walk(vs, in: g)) fails where Trail(vs, in: g) succeeds")


# NetworkX cycles are node lists, so parallel edges do not multiply cycles; with edge positions they do.
nxm = list(nx.simple_cycles(nx.MultiDiGraph([(0, 1), (0, 1), (1, 0)])))
ours = [es for es in all_edge_choices(M, [0, 1, 0], True)]
check("WK-512", nxm == [[0, 1]] and ours == [(0, 2), (1, 2)],
      f"NetworkX: {nxm} (one); edge-identified 2-cycles of M: {ours} (two)")
nxl = sorted(map(sorted, nx.simple_cycles(nx.MultiGraph([(1, 1), (1, 2), (1, 2)]))))
check("WK-513", nxl == [[1], [1, 2]], f"undirected multigraph: loop and digon {nxl}")
Gn = nx.Graph(); Gn.add_edge(0, 1, weight=-1)
check("WK-514", nx.find_negative_cycle(Gn, 0) == [0, 1, 0], "NetworkX: an undirected negative edge is the closed walk 0-1-0")

# ---------------------------------------------------------------- WK-6xx undirected
U = [(0, 1), (1, 2), (2, 0)]  # triangle, positions 0..2
check("WK-601", is_walk(U, [0, 1, 2, 0], [0, 1, 2], False) and is_walk(U, [0, 2, 1, 0], [2, 1, 0], False))
check("WK-602", is_walk(U, [1, 0], [0], False), "edge 0 = {0,1} walked from its v end")
check("WK-603", not is_walk(U, [0, 2], [0], False), "edge 0 does not join 0 and 2")
check("WK-604", is_walk(U, [0, 1, 0], [0, 0], False) and not is_trail(None, [0, 0]),
      "there and back on one edge: closed walk, not a circuit")
# Directed view of an undirected edge: arcs (p, False) u→v and (p, True) v→u are distinct positions.
arcs = [(u, v) for (u, v) in U for _ in (0,)]
DV = []
for (u, v) in U:
    DV += [(u, v), (v, u)]  # DirectedView order: (p, false) at 2p, (p, true) at 2p+1
check("WK-605", is_cycle_storage([0, 1], [0, 1]) and is_closed_walk_in(DV, [0, 1], [0, 1], True),
      "undirected negative edge 0-1 is a 2-cycle of g.directed: arcs (0,false),(0,true)")
# NetworkX: undirected cycles are distinct up to rotation and reversal; directed only rotation.
check("WK-606", len(list(nx.simple_cycles(nx.cycle_graph(3)))) == 1, "undirected triangle: one simple cycle")
check("WK-607", len(list(nx.simple_cycles(nx.DiGraph([(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)])))) == 5,
      "bidirected triangle: 2 triangles + 3 digons")
check("WK-608", list(nx.simple_cycles(nx.Graph([(0, 1)]))) == [], "a simple undirected edge is not a 2-cycle")
mg = nx.MultiGraph([(0, 1), (0, 1)])
check("WK-609", sorted(map(sorted, nx.simple_cycles(mg))) == [[0, 1]], "parallel undirected edges are a 2-cycle")
check("WK-610", list(nx.simple_cycles(nx.Graph([(0, 0)]))) == [[0]], "undirected self-loop is a 1-cycle")
cyc = list(nx.simple_cycles(nx.cycle_graph(4)))[0]
rev = [cyc[0]] + cyc[1:][::-1]
check("WK-611", len(cyc) == 4, f"NetworkX lists a cycle without repeating its start: {cyc}")

# ---------------------------------------------------------------- WK-7xx equality / hashing
A = ([0, 1, 2], [10, 11, 12])
for k in range(3):
    R = rotate(*A, k)
    check(f"WK-701 k={k}", rot_equal(A, R) and comm_hash(*A) == comm_hash(*R), f"{R}")
check("WK-702", not rot_equal(A, ([0, 2, 1], [12, 11, 10])), "reversal is not equal")
check("WK-703", rot_equal(A, reverse_cycle(*reverse_cycle(*A))), "reversing twice is the identity")
check("WK-704", reverse_cycle(*A) == ([0, 2, 1], [12, 11, 10]))
check("WK-705", not rot_equal(A, ([0, 1, 2], [10, 11, 13])), "same vertices, different edge")
check("WK-706", not rot_equal(A, ([1, 0, 2], [10, 11, 12])), "same edges, vertices shifted against them")
check("WK-707", rot_equal(([5], [9]), ([5], [9])) and not rot_equal(([5], [9]), ([5], [8])))
# Figure-eight circuit rotations: vertex 0 appears twice, but edges are distinct so one offset matches.
F8 = ([0, 1, 2, 0, 3, 4], [0, 1, 2, 3, 4, 5])
for k in range(6):
    R = rotate(*F8, k)
    check(f"WK-708 k={k}", rot_equal(F8, R) and comm_hash(*F8) == comm_hash(*R))
F8b = ([0, 3, 4, 0, 1, 2], [3, 4, 5, 0, 1, 2])
check("WK-709", rot_equal(F8, F8b), "rotation starting at the second visit of 0")
F8c = ([0, 3, 4, 0, 1, 2], [0, 1, 2, 3, 4, 5])
check("WK-710", not rot_equal(F8, F8c), "lobes swapped against their edges")
# Linear-time equality agrees with brute force on random storages.
for trial in range(2000):
    n = rng.randint(1, 6)
    va = [rng.randrange(3) for _ in range(n)]
    ea = rng.sample(range(8), n)
    k = rng.randrange(n)
    vb, eb = rotate(va, ea, k)
    if rng.random() < 0.5:
        i = rng.randrange(n)
        if rng.random() < 0.5:
            vb = vb[:i] + [rng.randrange(3)] + vb[i + 1:]
        else:
            eb = eb[:i] + [rng.choice([x for x in range(8) if x not in eb] or [eb[i]])] + eb[i + 1:]
    assert rot_equal((va, ea), (vb, eb)) == rot_equal_bruteforce((va, ea), (vb, eb))
    if rot_equal((va, ea), (vb, eb)):
        assert comm_hash(va, ea) == comm_hash(vb, eb)
check("WK-711", True, "2000 random circuits: linear equality == brute-force rotation equality; equal ⇒ equal hash")
# Walk equality is exact: rotation of a closed walk is a different Walk.
check("WK-712", ([0, 1, 2, 0], [10, 11, 12]) != ([1, 2, 0, 1], [11, 12, 10]))

# ---------------------------------------------------------------- WK-8xx conversions
check("WK-801", storage_to_closed_walk([0, 1, 2], [10, 11, 12]) == ([0, 1, 2, 0], [10, 11, 12]))
check("WK-802", closed_walk_to_storage([0, 1, 2, 0], [10, 11, 12]) == ([0, 1, 2], [10, 11, 12]))
check("WK-803", storage_to_closed_walk([4], [7]) == ([4, 4], [7]), "self-loop cycle as a walk")
# Cycle(walk) from a closed walk: distinct vertices apart from the closing repeat
w = ([0, 1, 2, 0, 3, 0], [0, 1, 2, 3, 4])
s = closed_walk_to_storage(*w)
check("WK-804", is_circuit_storage(*s) and not is_cycle_storage(*s))

# ---------------------------------------------------------------- WK-9xx weight / NetworkX path_weight
edges = [(1, 2, {"cost": 5, "dist": 6}), (2, 3, {"cost": 3, "dist": 4}), (1, 2, {"cost": 1, "dist": 2})]
E = [(a, b) for a, b, _ in edges]
cost = [d["cost"] for *_, d in edges]
dist = [d["dist"] for *_, d in edges]
for cls in [nx.MultiGraph, nx.MultiDiGraph]:
    H = cls()
    H.add_edges_from(edges)
    nxc = nx.path_weight(H, [1, 2, 3], "cost")
    check(f"WK-901 {cls.__name__}", nxc == 4 and weight([2, 1], cost) == 4 and weight([0, 1], cost) == 8,
          "NetworkX takes the lightest parallel edge (4); ours weighs the edges named: [2,1] → 4, [0,1] → 8")
for cls in [nx.Graph, nx.DiGraph]:
    H = cls()
    H.add_edges_from(edges)  # simple graph: the third edge overwrites the first's data
    check(f"WK-902 {cls.__name__}", nx.path_weight(H, [1, 2, 3], "cost") == 4 and nx.path_weight(H, [1, 2, 3], "dist") == 6)
check("WK-903", weight([], cost) == 0, "trivial walk weighs zero")
fw = [0.1, 0.2, 0.3]
c0 = weight([0, 1, 2], fw)
c1 = weight([1, 2, 0], fw)
check("WK-904", c0 != c1 and c0 == 0.6000000000000001 and c1 == 0.6,
      f"equal (rotated) cycles can weigh differently in floating point: {c0!r} vs {c1!r}")
check("WK-905", weight([0, 1, 2], [0.5, 0.25, 0.125]) == weight([1, 2, 0], [0.5, 0.25, 0.125]) == 0.875)

# ---------------------------------------------------------------- WK-10xx reversal / concatenation
# JGraphT testReversePathUndirected: 0-1 (w2), 1-2 (w3), 2-3 (w4)
U3 = [(0, 1), (1, 2), (2, 3)]
rv = reverse_walk([0, 1, 2, 3], [0, 1, 2])
check("WK-1001", rv == ([3, 2, 1, 0], [2, 1, 0]) and is_walk(U3, *rv, False) and weight(rv[1], [2, 3, 4]) == 9)
# Directed: the reverse is a walk of the reversed graph, not of g (JGraphT testReverseInvalidPathDirected).
D3 = [(0, 1), (1, 2), (2, 3)]
check("WK-1002", not is_walk(D3, *rv, True) and is_walk([(b, a) for a, b in D3], *rv, True))
# JGraphT testConcatPath1: 0→1, 1→2, 2→3, 3→1
C = [(0, 1), (1, 2), (2, 3), (3, 1)]
cat = ([0, 1, 2] + [2, 3, 1][1:], [0, 1] + [2, 3])
check("WK-1003", cat == ([0, 1, 2, 3, 1], [0, 1, 2, 3]) and is_walk(C, *cat, True))
check("WK-1004", ([0, 1] + [1][1:], [0] + []) == ([0, 1], [0]), "appending a trivial walk changes nothing")
check("WK-1005", reverse_walk([7], []) == ([7], []))
check("WK-1006", reverse_cycle([0, 1], [0, 1]) == ([0, 1], [1, 0]) and not rot_equal(([0, 1], [0, 1]), ([0, 1], [1, 0])),
      "a digon reversed is a different cycle value")
# Reversal of a walk in g.directed: reversing order alone gives arcs pointing backward.
check("WK-1007", is_walk(DV, [0, 1, 2], [0, 2], True) and not is_walk(DV, [2, 1, 0], [2, 0], True)
      and is_walk(DV, [2, 1, 0], [3, 1], True), "flip each arc's reversed flag to stay in g.directed")

# ---------------------------------------------------------------- migration fixtures (existing tests)
# SP-63: undirected negative edge 1-2 from cycle_graph(5): [1, 2] and arcs of edge {1,2}
check("WK-1201", is_cycle_storage([1, 2], [(1, False), (1, True)]))
# TR-105-ish: findCycle on 0→3→5→0 style; rotation equality makes the start irrelevant for ==
check("WK-1202", rot_equal(([0, 3, 5], ["a", "b", "c"]), ([3, 5, 0], ["b", "c", "a"])))
# NetworkX find_cycle returns edges, with orientation; its node sequence is the sources.
Gf = nx.DiGraph([(-1, 0), (0, 1), (1, 0), (1, 0), (2, 1), (3, 1)])
fc = list(nx.find_cycle(Gf, [0, 1, 2, 3]))
check("WK-1203", fc == [(0, 1), (1, 0)] and [u for u, _ in fc] == [0, 1], f"{fc}")
Gu = nx.Graph([(-1, 0), (0, 1), (1, 0), (1, 0), (2, 1), (3, 1), (2, 0)])
fu = list(nx.find_cycle(Gu, [0, 1, 2, 3]))
check("WK-1204", fu == [(0, 1), (1, 2), (2, 0)], f"{fu}")
fo = list(nx.find_cycle(nx.DiGraph([(0, 1), (0, 2), (1, 2)]), orientation="ignore"))
check("WK-1205", fo == [(0, 1, "forward"), (1, 2, "forward"), (0, 2, "reverse")],
      "orientation-ignoring cycle of a DAG: a cycle of the underlying undirected graph")
nb = nx.find_negative_cycle(nx.DiGraph([(0, 1, {"weight": -1}), (1, 0, {"weight": -1})]), 0)
check("WK-1206", nb[0] == nb[-1], f"NetworkX find_negative_cycle repeats the start at the end: {nb}")

print()
if FAILS:
    raise SystemExit(f"{len(FAILS)} FAILED: {FAILS}")
print("all checks passed")
