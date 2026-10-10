"""The Tours section of scripts/differential.py.

Two parts:

* `replay_catalog`: every row of Tests/Catalogs/Tours/cases.md, answered by the library
  (`GrafluentDifferential tours-catalog`, one batch) and rendered in the catalog's notation, must
  equal the Expected column. The rows' graphs come from Tests/Catalogs/Tours/ref.py's own
  builder, so nothing is parsed back out of the table but the calls. Every returned walk is also
  validated against its graph. Trap rows run one per process and must crash.
* `tours_case` / `compare_tours`: on every random case, three inputs are derived from the case
  alone (no random draws, so seeds stay reproducible): the case's own graph, a multigraph that is
  a random walk (closed, open, or with one more edge), and a weighted complete multigraph (a
  parallel copy and a self-loop sometimes added). Answers that ties cannot change are compared
  with NetworkX (whether a graph is Eulerian or has an Eulerian trail, isolated vertices
  removed first, since NetworkX counts them; the nearest-neighbour tour where no step has a tie;
  the optimum's weight against brute force; Christofides within 3/2 of it on metric inputs); the
  pinned walks and tours are compared exactly with ref.py's models of the documented procedures
  (Hierholzer under our row order, on the compressed sparse row's sorted rows too; the first
  Hamiltonian path or cycle in search order, its existence against a bitmask DP; nearest
  neighbour, JGraphT's 2-opt, the pinned Christofides, Held–Karp's lexicographically least
  optimum, on the case's own graph and, directed, on a complete digraph less some arcs with
  asymmetric weights, against brute force and a bitmask DP for existence). Every returned walk is validated on its own: the right edges, each once, joining the
  right vertices; a tour's edges are the lightest copies. With IGRAPH_C_LIB set, igraph's C
  `igraph_is_eulerian` is asked too, through ref.py's worker process.
"""

import importlib.util
import json
import os
import subprocess

import networkx as nx
from networkx.algorithms import approximation as nxa

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "Tests", "Catalogs", "Tours")

_spec = importlib.util.spec_from_file_location("tours_ref", os.path.join(CATALOG, "ref.py"))
REF = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(REF)

COVERED = {}


def covered(key, amount=1):
    COVERED[key] = COVERED.get(key, 0) + amount


# ---------------------------------------------------------------------------------------------
# Validation


def walk_problems(tag, g, kind, ans):
    """`ans` (vertices as text, edge positions) is a walk of its kind in g: an Eulerian circuit
    or trail through every edge once, a Hamiltonian path or cycle through every vertex once."""
    vs = [g.index[parse_label(x)] for x in ans["vertices"]]
    es = ans["edges"]
    if kind in ("circuit", "trail"):
        if g.m and not REF.check_trail(g, vs, es, kind == "circuit"):
            return [f"{tag}: {vs} / {es} is not an Eulerian {kind}"]
        return []
    closed = kind == "cycle"
    if sorted(vs) != list(range(g.n)) or len(set(es)) != len(es) or len(es) != (len(vs) if closed else len(vs) - 1):
        return [f"{tag}: {vs} / {es} is not a Hamiltonian {kind}"]
    for i, e in enumerate(es):
        a, b = vs[i], vs[(i + 1) % len(vs)] if closed else vs[i + 1]
        u, v = g.E[e]
        if (g.directed and (u, v) != (a, b)) or (not g.directed and {u, v} != {a, b}):
            return [f"{tag}: edge {e} does not join {a} and {b}"]
    return []


def tour_problems(tag, g, ans):
    """A Hamiltonian cycle through the lightest copy of each pair."""
    problems = walk_problems(tag, g, "cycle", ans)
    if problems:
        return problems
    order = [g.index[parse_label(x)] for x in ans["vertices"]]
    if REF.tour_of(g, order)[1] != ans["edges"]:
        problems.append(f"{tag}: edges {ans['edges']} are not the lightest copies {REF.tour_of(g, order)[1]}")
    return problems


# ---------------------------------------------------------------------------------------------
# The catalog


def parse_label(text):
    if isinstance(text, int):
        return text
    return int(text) if text.lstrip("-").isdigit() else text


def catalog_rows():
    """(id, group, name, input, call, expected, graph) for every row, the graphs as ref.py built
    them: its G.text() is wrapped to remember which graph each Input text came from."""
    texts = {}
    original = REF.G.text

    def text(self):
        t = original(self)
        texts.setdefault(t, self)
        return t

    REF.G.text = text
    try:
        REF.CASES.clear()
        REF.build()
    finally:
        REF.G.text = original
    nan, inf = float("nan"), float("inf")
    k3 = REF.K(3)
    literal = {
        "C(3)": REF.C(3), "P(3)": REF.P(3), "Cd(3)": REF.C(3, True), "Pd(3)": REF.P(3, True), "V []; E []": REF.G([], []),
        "C(4) weight 1": REF.weighted(REF.C(4), [1] * 4),
        "Double K(3) weights 1.0, nan, 2.0": REF.weighted(k3, [1.0, nan, 2.0], wtype="Double"),
        "K(32) weight 1": REF.weighted(REF.K(32), [1] * (32 * 31 // 2)),
        "K(26) weight 1": REF.weighted(REF.K(26), [1] * (26 * 25 // 2)),
        "Kd(26) weight 1": REF.weighted(REF.K(26, True), [1] * (26 * 25)),
        "Double K(3) weights 1.0, inf, 2.0": REF.weighted(k3, [1.0, inf, 2.0], wtype="Double"),
        "Double K(3) weights 1.0, -inf, 2.0": REF.weighted(k3, [1.0, -inf, 2.0], wtype="Double"),
        "Double V [0, 1, 2, 3]; E [0-1 1.0, 1-2 1.0, 2-3 1.0, 0-2 5.0, 0-3 5.0, 1-3 inf]":
            REF.G(range(4), [(0, 1), (1, 2), (2, 3), (0, 2), (0, 3), (1, 3)], w=[1.0, 1.0, 1.0, 5.0, 5.0, inf], wtype="Double"),
        "Double K(4) weights 1.0, 1.0, 1.0, inf, 1.0, -inf": REF.weighted(REF.K(4), [1.0, 1.0, 1.0, inf, 1.0, -inf], wtype="Double"),
        "Double Kd(3) weights 1.0, 2.0, nan, 1.0, 2.0, 1.0": REF.weighted(REF.K(3, True), [1.0, 2.0, nan, 1.0, 2.0, 1.0], wtype="Double"),
        "Double multigraph V [0, 1, 2]; E [0→1 1.0, 0→1 inf, 1→2 1.0, 2→0 1.0]":
            REF.G(range(3), [(0, 1), (0, 1), (1, 2), (2, 0)], True, w=[1.0, inf, 1.0, 1.0], wtype="Double"),
    }
    rows = []
    for i, (group, name, inp, call, expected, _) in enumerate(REF.CASES):
        g = texts.get(inp) or literal.get(inp)
        if g is None:
            raise ValueError(f"TO-{i + 1:03d}: no graph for {inp}")
        rows.append((f"TO-{i + 1:03d}", group, name, inp, call, expected, g))
    with open(os.path.join(CATALOG, "cases.md")) as f:
        listed = sum(1 for line in f if line.startswith("| TO-"))
    if listed != len(rows):
        raise ValueError(f"cases.md has {listed} rows, ref.py builds {len(rows)}")
    return rows


def parse_call(call, g):
    """(name, from, to, tour) as vertex numbers; a label that is not a vertex becomes a number
    past the last vertex."""
    def number(text):
        label = parse_label(text.strip())
        return g.index[label] if label in g.index else g.n + 100

    name, _, args = call.partition("(")
    args = args.rstrip(")")
    frm = to = tour = None
    if args.startswith("improving: ["):
        inner = args[len("improving: ["): args.index("]")]
        tour = [number(x) for x in inner.split(", ") if x]
    elif args.startswith("from: "):
        rest = args[len("from: "):]
        parts = [p for p in rest.split(", ") if p and p != "weight:"]
        frm = number(parts[0])
        if len(parts) > 1 and parts[1].startswith("to: "):
            to = number(parts[1][len("to: "):])
    return name, frm, to, tour


def request(g, name, frm, to, tour):
    return {
        "directed": g.directed, "multi": g.multi(), "labels": [str(x) for x in g.labels], "edges": [[u, v] for u, v in g.E],
        "weights": None if g.w is None else [repr(x) if isinstance(x, float) else str(x) for x in g.w],
        "wtype": g.wtype, "call": name, "from": frm, "to": to, "tour": tour,
    }


def kind_of(group):
    for prefix, kind in (("EulerianCircuit", "circuit"), ("EulerianTrail", "trail"), ("HamiltonianPath", "path"),
                         ("HamiltonianCycle", "cycle")):
        if group.startswith(prefix):
            return kind
    return "tour"


def render(g, group, ans):
    if ans.get("flag") is not None:
        return str(ans["flag"]).lower()
    walk = ans.get("walk")
    if walk is None:
        return "nil"
    kind = kind_of(group)
    text = f"{'cycle' if kind == 'tour' else kind} {REF.fmtl(walk['vertices'])}; edges {REF.fmtl(walk['edges'])}"
    if kind == "tour":
        total = 0 if g.wtype == "Int" else 0.0
        for e in walk["edges"]:
            total = total + g.w[e]
        text += f"; weight {REF.fmtv(total)}"
    return text


def replay_catalog(executable):
    """Replays every catalog row; returns the problems found."""
    batch, expected, traps, skipped = [], [], [], []
    for ident, group, name, inp, call, exp, g in catalog_rows():
        call = call.strip("`")
        fname, frm, to, tour = parse_call(call, g)
        if exp.startswith("trap"):
            if tour is not None and len(set(tour)) != len(tour):
                # A Cycle never repeats a vertex, so no call can pass this tour: the type rules it out.
                skipped.append(ident)
                continue
            traps.append((ident, request(g, fname, frm, to, tour)))
            continue
        batch.append(request(g, fname, frm, to, tour))
        expected.append((ident, group, g, exp))
    problems = []
    run = subprocess.run([executable, "tours-catalog"], input=json.dumps(batch), capture_output=True, text=True, timeout=300)
    if run.returncode != 0:
        return [f"tours catalog: the library crashed: {run.stderr.strip()[-800:]}"]
    for (ident, group, g, exp), ans in zip(expected, json.loads(run.stdout)):
        mine = render(g, group, ans)
        if mine != exp:
            problems.append(f"{ident}: expected {exp}, library {mine}")
        walk = ans.get("walk")
        if walk is not None:
            kind = kind_of(group)
            problems += tour_problems(ident, g, walk) if kind == "tour" else walk_problems(ident, g, kind, walk)
    crashed = 0
    for ident, req in traps:
        try:
            one = subprocess.run([executable, "tours-catalog"], input=json.dumps([req]), capture_output=True, text=True, timeout=60)
            if one.returncode == 0:
                problems.append(f"{ident}: expected a trap, the library returned {one.stdout[:200]}")
            else:
                crashed += 1
        except subprocess.TimeoutExpired:
            problems.append(f"{ident}: expected a trap, the library did not finish")
    note = f"; {', '.join(skipped)} not expressible (a Cycle cannot repeat a vertex)" if skipped else ""
    print(f"tours catalog: {len(batch)} rows answered, {crashed} of {len(traps)} traps trapped{note}, {len(problems)} problem(s)")
    return problems


# ---------------------------------------------------------------------------------------------
# Random cases


def tours_case(case):
    """The Tours inputs for a case, from the case alone."""
    n, edges = case["n"], case["edges"]
    seed = (n * 7919 + len(edges) * 104729 + sum((i + 1) * (u * 31 + v * 7 + w) for i, (u, v, w) in enumerate(edges))) % (1 << 63)
    g = REF.LCG(seed)
    # An Eulerian multigraph from a walk; a third open, one in five with an extra edge.
    length = 1 + g.next() % (3 * n + 3)
    walk = [0] + [g.next() % n for _ in range(length)]
    if g.next() % 3 and walk[-1] != 0:
        walk.append(0)
    walk_edges = [[walk[i], walk[i + 1]] for i in range(len(walk) - 1)]
    if g.next() % 5 == 0:
        walk_edges.append([g.next() % n, g.next() % n])
    # A complete multigraph on 3 to 10 vertices: Manhattan points (a metric), small integers
    # (ties), or dyadic doubles.
    k = 3 + g.next() % 8
    mode = g.next() % 3
    pairs = [[a, b] for a in range(k) for b in range(a + 1, k)]
    if mode == 0:
        pts = [(g.next() % 20, g.next() % 20) for _ in range(k)]
        weights = [abs(pts[a][0] - pts[b][0]) + abs(pts[a][1] - pts[b][1]) for a, b in pairs]
    elif mode == 1:
        weights = [g.next() % 26 - 5 for _ in pairs]
    else:
        weights = [(g.next() % 40 - 8) / 4 for _ in pairs]
    if g.next() % 3 == 0:
        a, b = pairs[g.next() % len(pairs)]
        pairs.append([b, a])
        weights.append(weights[pairs.index([a, b])] + (g.next() % 3 - 1) * (1 if mode != 2 else 0.25))
    if g.next() % 4 == 0:
        v = g.next() % k
        pairs.append([v, v])
        weights.append(-9 if mode != 2 else -9.0)
    # Every twentieth case, a larger complete graph (30 to 120 vertices) for the heuristics, where
    # 2-opt makes many moves over long segments.
    large_n = 30 + g.next() % 91 if seed % 20 == 0 else 0
    large_pairs = [[a, b] for a in range(large_n) for b in range(a + 1, large_n)]
    if large_n and g.next() % 2:
        pts = [(g.next() % 1000, g.next() % 1000) for _ in range(large_n)]
        large_weights = [abs(pts[a][0] - pts[b][0]) + abs(pts[a][1] - pts[b][1]) for a, b in large_pairs]
    else:
        large_weights = [g.next() % 50 for _ in large_pairs]
    improving = list(range(k))
    for x in range(k - 1, 0, -1):
        y = g.next() % (x + 1)
        improving[x], improving[y] = improving[y], improving[x]
    start = g.next() % k
    # Drawn after every earlier input, so those stay as they were: the complete digraph on k vertices,
    # each arc kept with probability 7/8 (every other case all of them), asymmetric weights -5 … 20.
    keep_all = g.next() % 2 == 0
    arcs = [[a, b] for a in range(k) for b in range(k) if a != b and (g.next() % 8 != 0 or keep_all)]
    arc_weights = [g.next() % 26 - 5 for _ in arcs]
    return {
        "walk": walk_edges, "complete": pairs, "completeN": k,
        "weights": [repr(w) if isinstance(w, float) else str(w) for w in weights], "wtype": "Double" if mode == 2 else "Int",
        "start": start, "improving": improving, "hamiltonian": n <= 9,
        "directedComplete": arcs, "directedWeights": [str(w) for w in arc_weights],
        "shortestOnCase": 3 <= n <= 11, "caseWeights": [str(w) for _, _, w in edges],
        "largeN": large_n, "large": large_pairs, "largeWeights": [str(w) for w in large_weights],
    }


def walk_of(ans):
    return None if ans is None else ([int(x) for x in ans["vertices"]], ans["edges"])


def model(res):
    return None if res is None else (list(res[0]), list(res[1]))


def without_isolated(g):
    h = REF.nx_graph(g)
    h.remove_nodes_from([v for v in list(h.nodes) if h.degree(v) == 0])
    return h


def eulerian_problems(tag, g, ans, start):
    problems = []
    eu, tr, _ = REF.euler_status(g)
    if (ans["isEulerian"], ans["hasTrail"]) != (eu, tr):
        problems.append(f"{tag}: isEulerian/hasEulerianTrail {ans['isEulerian']}/{ans['hasTrail']}, the definitions {eu}/{tr}")
    h = without_isolated(g)
    if h.number_of_nodes():
        if nx.is_eulerian(h) != ans["isEulerian"] or nx.has_eulerian_path(h) != ans["hasTrail"]:
            problems.append(f"{tag}: NetworkX (isolated vertices removed) {nx.is_eulerian(h)}/{nx.has_eulerian_path(h)}, library {ans['isEulerian']}/{ans['hasTrail']}")
        covered("eulerian graphs" if eu else "trail-only graphs" if tr else "neither")
    if os.environ.get("IGRAPH_C_LIB"):
        REF.igraph_claim(g, "is")
    for key, kind, expect in (("circuit", "circuit", REF.euler_circuit(g)), ("trail", "trail", REF.euler_trail(g)),
                              ("circuitFrom", "circuit", None if start is None else REF.euler_circuit(g, start)),
                              ("trailFrom", "trail", None if start is None else REF.euler_trail(g, start))):
        mine = ans.get(key)
        if model(expect) != walk_of(mine):
            problems.append(f"{tag} {key}: library {walk_of(mine)}, Hierholzer's pinned walk {model(expect)}")
        if mine is not None:
            problems += walk_problems(f"{tag} {key}", g, kind, mine)
            covered(f"{kind}s checked")
    return problems


def hamiltonian_problems(tag, g, t, s, target, prefix=""):
    problems = []
    queries = [("hamiltonianPath", "path", REF.ham_path(g), REF.ham_dp_exists(g)),
               ("hamiltonianCycle", "cycle", REF.ham_cycle(g), REF.ham_dp_exists(g, cycle=True))]
    if not prefix:
        queries += [("hamiltonianPathFrom", "path", REF.ham_path(g, s), REF.ham_dp_exists(g, start=s)),
                    ("hamiltonianPathFromTo", "path", REF.ham_path(g, s, target),
                     REF.ham_dp_exists(g, start=s, target=target) if s != target or g.n == 1 else False)]
    for key, kind, expect, exists in queries:
        mine = t.get(prefix + key[0].upper() + key[1:] if prefix else key)
        if model(expect) != walk_of(mine):
            problems.append(f"{tag} {key}: library {walk_of(mine)}, the first in search order {model(expect)}")
        if (mine is not None) != exists:
            problems.append(f"{tag} {key}: found {mine is not None}, the bitmask DP says {exists}")
        if mine is not None:
            problems += walk_problems(f"{tag} {key}", g, kind, mine)
            covered(f"Hamiltonian {kind}s found")
        else:
            covered(f"Hamiltonian {kind}s absent")
    return problems


def compare_tours(case, t):
    problems = []
    n, directed = case["n"], case["directed"]
    tc = case["tours"]
    if not t["positionsInOrder"]:
        problems.append("tours: a graph's edge positions are not the input order")
    start = case["sources"][0]
    g = REF.G(range(n), [(u, v) for u, v, _ in case["edges"]], directed)
    problems += eulerian_problems("graph", g, t["graph"], start)
    gc = None
    if directed:
        gc = REF.G(range(n), sorted({(u, v) for u, v, _ in case["edges"]}), True)
        if [list(e) for e in gc.E] != t["csrEdges"]:
            problems.append(f"csr: edges {t['csrEdges'][:10]} are not the sorted case edges")
        problems += eulerian_problems("csr", gc, t["csr"], start)
    gw = REF.G(range(n), [tuple(e) for e in tc["walk"]], directed)
    problems += eulerian_problems("walk", gw, t["walk"], start)
    if tc["hamiltonian"]:
        problems += hamiltonian_problems("graph", g, t, start, case["target"])
        if gc is not None:
            problems += hamiltonian_problems("csr", gc, t, start, case["target"], prefix="csr")
    # Tours on the complete multigraph.
    floating = tc["wtype"] == "Double"
    weights = [float(w) if floating else int(w) for w in tc["weights"]]
    gt = REF.G(range(tc["completeN"]), [tuple(e) for e in tc["complete"]], False, w=weights, wtype=tc["wtype"])
    k = gt.n
    nn = REF.nearest_neighbor(gt, 0)
    s = tc["start"] % k
    best = REF.brute_tsp(gt) if k <= 9 else None
    W = REF.simple_weights(gt)
    expected = {
        "nearestNeighbor": nn, "nearestNeighborFrom": REF.nearest_neighbor(gt, s), "twoOpt": REF.two_opt(gt, nn),
        "twoOptImproving": REF.two_opt(gt, tc["improving"]), "christofides": REF.christofides(gt)[0],
        "shortest": REF.held_karp(gt),
    }
    for key, order in expected.items():
        mine = t.get(key)
        if mine is None:
            problems.append(f"tour {key}: library nil, the model {order}")
            continue
        problems += tour_problems(f"tour {key}", gt, mine)
        got = [int(x) for x in mine["vertices"]]
        if got != order:
            problems.append(f"tour {key}: library {got}, the pinned procedure {order}")
        weight = REF.tour_weight(W, got)
        if best is not None and weight < best[0]:
            problems.append(f"tour {key}: weight {weight} below the optimum {best[0]}")
        covered(f"{key} tours")
    if best is not None and t.get("shortest") is not None:
        if REF.tour_weight(W, [int(x) for x in t["shortest"]["vertices"]]) != best[0]:
            problems.append(f"tour shortest: not the optimum {best[0]} (brute force)")
        covered("optima against brute force")
        if REF.is_metric(gt) and t.get("christofides") is not None:
            if REF.tour_weight(W, [int(x) for x in t["christofides"]["vertices"]]) > 1.5 * best[0] + 1e-9:
                problems.append("tour christofides: above 3/2 of the optimum on a metric")
            covered("Christofides within 3/2 on metrics")
    if not REF.nn_ties(gt, s):
        h = REF.nx_simple_weighted(gt)
        theirs = nxa.greedy_tsp(h, source=s)[:-1]
        if t.get("nearestNeighborFrom") is not None and [int(x) for x in t["nearestNeighborFrom"]["vertices"]] != theirs:
            problems.append(f"tour nearestNeighborFrom: NetworkX greedy_tsp {theirs} (no ties)")
        covered("nearest neighbour against NetworkX greedy_tsp")
    if tc["largeN"]:
        gl = REF.G(range(tc["largeN"]), [tuple(e) for e in tc["large"]], False, w=[int(w) for w in tc["largeWeights"]])
        nn = REF.nearest_neighbor(gl, 0)
        for key, order in (("largeNearestNeighbor", nn), ("largeTwoOpt", REF.two_opt(gl, nn)), ("largeChristofides", REF.christofides(gl)[0])):
            mine = t.get(key)
            got = None if mine is None else [int(x) for x in mine["vertices"]]
            if got != order:
                problems.append(f"{key} on {gl.n} vertices: library {got}, the pinned procedure {order}")
            elif mine is not None:
                problems += tour_problems(key, gl, mine)
            covered(f"{key} tours")
    gd = REF.G(range(k), [tuple(e) for e in tc["directedComplete"]], True, w=[int(w) for w in tc["directedWeights"]])
    order = REF.held_karp(gd)
    mine = t.get("shortestDirected")
    got = None if mine is None else [int(x) for x in mine["vertices"]]
    if got != order:
        problems.append(f"directed shortestTour: library {got}, Held–Karp {order}")
    if mine is not None:
        problems += tour_problems("directed shortestTour", gd, mine)
    if (order is not None) != REF.ham_dp_exists(gd, cycle=True):
        problems.append("directed shortestTour: existence differs from the bitmask DP")
    if k <= 8:
        b = REF.brute_tsp(gd)
        if (b is None) != (order is None) or (b is not None and b[1] != order):
            problems.append(f"directed shortestTour: brute force {b}, Held–Karp {order}")
        covered("directed Held–Karp against brute force")
    covered("directed Held–Karp, found" if mine is not None else "directed Held–Karp, none")
    if tc["shortestOnCase"]:
        gs = REF.G(range(n), [(u, v) for u, v, _ in case["edges"]], directed, w=[w for _, _, w in case["edges"]])
        order = REF.held_karp(gs)
        mine = t.get("shortestOnCase")
        got = None if mine is None else [int(x) for x in mine["vertices"]]
        if got != order:
            problems.append(f"shortestTour on the case: library {got}, Held–Karp {order}")
        if mine is not None:
            problems += tour_problems("shortestTour on the case", gs, mine)
            covered(f"Held–Karp on sparse {'digraphs' if directed else 'graphs'}, found")
        else:
            covered(f"Held–Karp on sparse {'digraphs' if directed else 'graphs'}, none")
        if n <= 9:
            b = REF.brute_tsp(gs)
            if (b is None) != (order is None) or (b is not None and b[1] != order):
                problems.append(f"shortestTour on the case: brute force {b}")
    return problems


def finish():
    """igraph C's answers for every graph asked (with IGRAPH_C_LIB): the problems found."""
    if not os.environ.get("IGRAPH_C_LIB") or not REF.IGRAPH_CALLS:
        return []
    REF.FAILS.clear()
    REF.run_igraph()
    covered("igraph C is_eulerian calls", len(REF.IGRAPH_CALLS))
    REF.IGRAPH_CALLS.clear()
    return list(REF.FAILS)
