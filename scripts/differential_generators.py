"""The generators section of scripts/differential.py: NamedGraphs and RandomGraphs against NetworkX
and igraph.

* `generator_case(case)`: the inputs, derived from the case alone (a stable hash seeds the
  choices, so a seed reproduces them whatever else runs): the case's degree sequences, often
  perturbed, for the graphicality tests and Havel–Hakimi; a stream seed and parameters for each
  random family; parameters for the named families.
* `compare_generators(case, mine)`: graphicality decisions against `is_graphical` and
  `is_digraphical`; Havel–Hakimi and Kleitman–Wang edge for edge against `havel_hakimi_graph` and
  `directed_havel_hakimi_graph`; the random families, run by NetworkX on the same stream
  (Tests/Catalogs/RandomGraphs/ref.py's StreamRandom), edge for edge: `configuration_model` and
  `directed_configuration_model` (as multisets, and in order against the catalog's port),
  `expected_degree_graph(selfloops=False)`, `newman_watts_strogatz_graph`,
  `connected_watts_strogatz_graph` (nil where it raises), `random_uniform_k_out_graph`,
  `scale_free_graph` and `bipartite.gnmk_random_graph`; Holme–Kim against the catalog's port of
  the pinned procedure, its edge count m(n − m) and m older neighbors per later vertex; every degree
  sequence the families promise; the named families edge for edge against NetworkX where it numbers
  the same way, igraph for de Bruijn and Kautz, and isomorphism for the rest.
"""

import importlib.util
import json
import os
import random
import zlib
from collections import Counter

import igraph
import networkx as nx
from networkx.generators.directed import random_uniform_k_out_graph

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_spec = importlib.util.spec_from_file_location("random_graphs_ref", os.path.join(ROOT, "Tests", "Catalogs", "RandomGraphs", "ref.py"))
REF = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(REF)

COVERED = {}


def covered(key, amount=1):
    COVERED[key] = COVERED.get(key, 0) + amount


def _simple_degrees(case):
    n = case["n"]
    pairs = {(min(u, v), max(u, v)) for u, v, _ in case["edges"] if u != v}
    degrees = [0] * n
    for u, v in pairs:
        degrees[u] += 1
        degrees[v] += 1
    arcs = {(u, v) for u, v, _ in case["edges"] if u != v}
    ins, outs = [0] * n, [0] * n
    for u, v in arcs:
        outs[u] += 1
        ins[v] += 1
    return degrees, ins, outs


def generator_case(case):
    rng = random.Random(zlib.crc32(json.dumps([case["n"], case["edges"]]).encode()))
    n = case["n"]
    degrees, ins, outs = _simple_degrees(case)
    if rng.random() < 0.5:
        # A perturbation that may or may not keep the sequence graphical.
        i = rng.randrange(n)
        degrees[i] = max(0, degrees[i] + rng.choice([-2, -1, 1, 2]))
        if rng.random() < 0.3 and n >= 2:
            j = rng.randrange(n)
            degrees[j] = max(0, degrees[j] + rng.choice([-1, 1]))
    if rng.random() < 0.5 and n >= 2:
        i, j = rng.randrange(n), rng.randrange(n)
        if ins[i] > 0:
            ins[i] -= 1
            ins[j] += 1
    stub = [rng.randrange(5) for _ in range(min(n, 40))]
    if sum(stub) % 2:
        stub.append(1)
    stub_out = [rng.randrange(4) for _ in range(min(n, 30))]
    stub_in = [0] * len(stub_out)
    for _ in range(sum(stub_out)):
        stub_in[rng.randrange(len(stub_in))] += 1
    weights = [d + rng.choice([0.0, 0.5, 1.5]) for d in degrees[:60]]
    hn = max(n, 2) if n <= 60 else 60
    hm = rng.randint(1, min(4, hn))
    sn = max(n, 1) if n <= 60 else 60
    sk = min(2 * rng.randint(0, 3), sn - sn % 2)
    kn = min(n, 60)
    kk = rng.randint(0, min(max(kn - 1, 0), 6))
    preset = rng.choice([(0.41, 0.54, 0.05, 0.2, 0.0), (0.3, 0.4, 0.3, 0.0, 0.5), (0.6, 0.2, 0.2, 1.0, 1.0)])
    a, b = rng.randint(0, 8), rng.randint(0, 8)
    cn = max(min(n, 40), 1)
    offsets = [o for o in (rng.randint(-cn, cn) for _ in range(rng.randint(0, 3))) if o % cn != 0]
    pn = min(n, 27) + 3
    kneser_n = rng.randint(1, 8)
    lcf_n = max(min(n, 40), 3)
    shifts = [s for s in (rng.randint(-lcf_n, lcf_n) for _ in range(rng.randint(0, 4))) if s % lcf_n != 0]
    primes = [p for p in range(2, 60) if all(p % d for d in range(2, p))]
    return {
        "degrees": degrees, "inDegrees": ins, "outDegrees": outs,
        "seed": rng.randrange(1 << 63),
        "stubDegrees": stub, "stubIn": stub_in, "stubOut": stub_out,
        "weights": weights,
        "holmeKim": [hn, hm, rng.choice([0.0, 0.3, 0.7, 1.0])],
        "duplication": [max(min(n, 60), 2), rng.choice([0.1, 0.3, 0.7, 1.0])],
        "smallWorld": [sn, sk, rng.choice([0.0, 0.2, 0.5, 1.0]), rng.randint(0, 5)],
        "kOut": [kn, kk],
        "scaleFree": [min(n, 80) + 3, *preset],
        "bipartite": [a, b, rng.randint(0, a * b)],
        "circulant": [cn] + offsets,
        "petersen": [pn, rng.randint(1, (pn - 1) // 2)],
        "kneser": [kneser_n, rng.randint(1, kneser_n)],
        "windmill": [rng.randint(2, 5), rng.randint(2, 5)],
        "trees": [rng.randint(0, 9), rng.randint(1, 4), rng.randint(0, 60)],
        "words": [rng.randint(1, 3), rng.randint(1, 4), rng.randint(2, 4), rng.randint(1, 3)],
        "lattice": [rng.randint(0, 5), rng.randint(0, 6)],
        "lcf": [lcf_n, rng.randint(0, 3)] + shifts,
        "expanders": [rng.randint(1, 7), rng.choice(primes), rng.choice([p for p in primes if p % 4 == 1]),
                      rng.choice([p for p in primes if p % 4 == 3])],
        "named": rng.random() < 0.05,
    }


def _pairs(H):
    return sorted((min(u, v), max(u, v)) for u, v in H.edges())


def _arcs(H):
    return sorted(H.edges())


def compare_generators(case, mine):
    g = case["generators"]
    problems = []

    def check(label, ok):
        if not ok:
            problems.append(f"generators: {label}")

    tup = lambda es: [tuple(e) for e in es]  # noqa: E731
    # Graphicality and Havel–Hakimi.
    graphical = nx.is_graphical(g["degrees"])
    check(f"isGraphical({g['degrees']}) is {mine['isGraphical']}", mine["isGraphical"] == graphical)
    covered("graphical" if graphical else "not graphical")
    if graphical and mine.get("havelHakimi") is not None:
        H = nx.havel_hakimi_graph(g["degrees"])
        # NetworkX 3.7 numbers the vertices of nonzero degree 0, 1, … in order, so with a zero
        # before the last nonzero degree its labels are not the sequence's indices (its graph has
        # edges at vertices of degree 0). The library uses the indices; the procedure is the same
        # under that order-preserving relabeling.
        nonzero = [v for v, d in enumerate(g["degrees"]) if d > 0]
        theirs = sorted((min(nonzero[u], nonzero[v]), max(nonzero[u], nonzero[v])) for u, v in H.edges())
        check("havelHakimi differs from havel_hakimi_graph", sorted(tup(mine["havelHakimi"])) == theirs)
        covered("Havel–Hakimi with interleaved zeros", nonzero != list(range(len(nonzero))))
        built = [0] * len(g["degrees"])
        for u, v in mine["havelHakimi"]:
            built[u] += 1
            built[v] += 1
        check("havelHakimi's degrees", built == g["degrees"])
    digraphical = nx.is_digraphical(g["inDegrees"], g["outDegrees"])
    check(f"isDigraphical is {mine['isDigraphical']}", mine["isDigraphical"] == digraphical)
    covered("digraphical" if digraphical else "not digraphical")
    if digraphical and mine.get("kleitmanWang") is not None:
        H = nx.directed_havel_hakimi_graph(g["inDegrees"], g["outDegrees"])
        check("Kleitman–Wang differs from directed_havel_hakimi_graph", tup(mine["kleitmanWang"]) == _arcs(H))
    check("the conformers disagree", mine["conformersAgree"])

    seed = g["seed"]
    stream = lambda: REF.StreamRandom(seed)  # noqa: E731
    # The configuration models: NetworkX's multisets, and the port's order.
    H = nx.configuration_model(g["stubDegrees"], seed=stream())
    check("configurationModel differs from configuration_model",
          Counter((min(u, v), max(u, v)) for u, v in mine["configurationModel"]) == Counter(_pairs(H)))
    model = REF.configuration_model(g["stubDegrees"], REF.Xoshiro256StarStar(seed))
    check("configurationModel's order", tup(mine["configurationModel"]) == model.edges)
    H = nx.directed_configuration_model(g["stubIn"], g["stubOut"], seed=stream())
    check("directed configurationModel differs", Counter(tup(mine["directedConfigurationModel"])) == Counter(H.edges()))
    # Chung–Lu.
    try:
        H = nx.expected_degree_graph(g["weights"], seed=stream(), selfloops=False)
        theirs = _pairs(H)
    except ZeroDivisionError:  # 1 − p rounds to 1; the library ends that sweep
        theirs = sorted(REF.chung_lu(g["weights"], REF.Xoshiro256StarStar(seed)).edges)
    check("chungLu differs from expected_degree_graph", tup(mine["chungLu"]) == theirs)
    check("chungLu directed is not both arcs", tup(mine["chungLuDirected"]) == sorted(theirs + [(v, u) for u, v in theirs]))
    covered("Chung–Lu edges", len(theirs))
    # Holme–Kim: the port, the counts and the older neighbors.
    hn, hm, hp = int(g["holmeKim"][0]), int(g["holmeKim"][1]), g["holmeKim"][2]
    model = REF.holme_kim(hn, hm, hp, REF.Xoshiro256StarStar(seed))
    check("holmeKim differs from the port", tup(mine["holmeKim"]) == model.edges)
    check("holmeKim's edge count", len(mine["holmeKim"]) == hm * (hn - hm))
    older = Counter(max(u, v) for u, v in mine["holmeKim"])
    check("holmeKim's older neighbors", all(older[v] == (hm if v >= hm else 0) for v in range(hn)))
    check("holmeKim directed", tup(mine["holmeKimDirected"]) == sorted((v, u) for u, v in mine["holmeKim"]))
    # Duplication–divergence: the port, the seed edge and an older neighbor for every later vertex.
    dn, dp = int(g["duplication"][0]), g["duplication"][1]
    model = REF.duplication_divergence(dn, dp, REF.Xoshiro256StarStar(seed))
    check("duplicationDivergence differs from the port", tup(mine["duplicationDivergence"]) == model.edges)
    check("duplicationDivergence start", tup(mine["duplicationDivergence"])[:1] == [(0, 1)])
    check("duplicationDivergence older neighbors", all(any(u < v == w for u, w in tup(mine["duplicationDivergence"])) for v in range(2, dn)))
    check("duplicationDivergence directed", tup(mine["duplicationDivergenceDirected"]) == sorted((v, u) for u, v in mine["duplicationDivergence"]))
    H = nx.powerlaw_cluster_graph(hn, hm, hp, seed=stream())
    covered("Holme–Kim = NetworkX", _pairs(H) == tup(mine["holmeKim"]))
    # Newman–Watts–Strogatz and connected Watts–Strogatz.
    sn, sk, sp, tries = int(g["smallWorld"][0]), int(g["smallWorld"][1]), g["smallWorld"][2], int(g["smallWorld"][3])
    H = nx.newman_watts_strogatz_graph(sn, sk, sp, seed=stream())
    check("newmanWattsStrogatz differs", tup(mine["newmanWattsStrogatz"]) == _pairs(H))
    try:
        H = nx.connected_watts_strogatz_graph(sn, sk, sp, tries=tries, seed=stream())
        theirs = _pairs(H)
    except nx.NetworkXError:
        theirs = None
    except nx.NetworkXPointlessConcept:
        theirs = None
    mine_cws = None if mine.get("connectedWattsStrogatz") is None else tup(mine["connectedWattsStrogatz"])
    check(f"connectedWattsStrogatz differs (tries {tries})", mine_cws == theirs)
    covered("connected Watts–Strogatz nil", theirs is None)
    # Random k-out.
    kn, kk = g["kOut"]
    H = random_uniform_k_out_graph(kn, kk, self_loops=False, with_replacement=False, seed=stream())
    check("randomKOut differs", tup(mine["kOut"]) == _arcs(H))
    check("randomKOut undirected", tup(mine["kOutUndirected"]) == sorted({(min(u, v), max(u, v)) for u, v in H.edges()}))
    # Directed scale-free.
    s = g["scaleFree"]
    H = nx.scale_free_graph(int(s[0]), *s[1:], seed=stream())
    check("scaleFree differs", Counter(tup(mine["scaleFree"])) == Counter(H.edges()))
    # G(a, b, m).
    a, b, m = g["bipartite"]
    model = REF.random_bipartite_m(a, b, m, REF.Xoshiro256StarStar(seed))
    check("randomBipartite(edgeCount:) differs from the port", tup(mine["bipartite"]) == model.edges)
    model = REF.random_bipartite_m(a, b, m, REF.Xoshiro256StarStar(seed), True)
    check("directed randomBipartite(edgeCount:) differs from the port", tup(mine["bipartiteDirected"]) == model.edges)
    # gnmk_random_graph draws the right vertex from the list of a set, which is ascending only when
    # CPython's set happens to iterate that way.
    bottom = list(set(range(a + b)) - set(range(a)))
    if 2 * m <= a * b and a != 1 and b != 1 and bottom == sorted(bottom):
        H = nx.bipartite.gnmk_random_graph(a, b, m, seed=stream())
        check("randomBipartite(edgeCount:) differs from gnmk_random_graph", tup(mine["bipartite"]) == _pairs(H))
        covered("G(a, b, m) = NetworkX")

    # The named families.
    named = mine["named"]
    counts = mine["namedCounts"]

    def exact(name, H, directed_factor=2):
        check(f"{name} differs from NetworkX", tup(named[name]) == _pairs(H) and counts[name][0] == H.number_of_nodes())
        check(f"{name} directed arcs", counts[name][2] == directed_factor * counts[name][1])

    def iso(name, H):
        G = nx.Graph()
        G.add_nodes_from(range(counts[name][0]))
        G.add_edges_from(tup(named[name]))
        check(f"{name} is not isomorphic to NetworkX's", nx.is_isomorphic(G, H))
        check(f"{name} directed arcs", counts[name][2] == 2 * counts[name][1])

    cn, offsets = g["circulant"][0], g["circulant"][1:]
    exact("circulant", nx.circulant_graph(cn, offsets))
    exact("generalizedPetersen", nx.generalized_petersen_graph(*g["petersen"]))
    kn_, kk_ = g["kneser"]
    combos = {c: i for i, c in enumerate(__import__("itertools").combinations(range(kn_), kk_))}
    K = nx.relabel_nodes(nx.kneser_graph(kn_, kk_), combos)
    K.add_nodes_from(range(len(combos)))
    exact("kneser", K)
    exact("windmill", nx.windmill_graph(*g["windmill"]))
    exact("binomialTree", nx.binomial_tree(g["trees"][0]), 1)
    exact("fullRaryTree", nx.full_rary_tree(g["trees"][1], g["trees"][2]), 1)
    rows, columns = g["lattice"]
    exact("triangularLattice", nx.convert_node_labels_to_integers(nx.triangular_lattice_graph(rows, columns, with_positions=False)))
    exact("hexagonalLattice", nx.convert_node_labels_to_integers(nx.hexagonal_lattice_graph(rows, columns, with_positions=False)))
    exact("lcf", nx.LCF_graph(g["lcf"][0], g["lcf"][2:], g["lcf"][1]))
    # NetworkX builds the first two as multigraphs with loops: the simple graph drops the loops.
    side, chordal_p, paley_p, tournament_p = g["expanders"]
    def simple(H):
        G = nx.Graph()
        G.add_nodes_from(H.nodes())
        G.add_edges_from((u, v) for u, v in H.edges() if u != v)
        return G
    exact("margulisGabberGalil", simple(nx.relabel_nodes(nx.margulis_gabber_galil_graph(side), lambda xy: xy[0] * side + xy[1])))
    exact("chordalCycle", simple(nx.chordal_cycle_graph(chordal_p)))
    exact("paley", nx.paley_graph(paley_p).to_undirected())
    check("paley tournament differs from NetworkX", tup(mine["paleyTournament"]) == _arcs(nx.paley_graph(tournament_p)))
    m_, length = g["words"][0], g["words"][1]
    check("deBruijn differs from igraph", sorted(tup(named["deBruijn"])) == sorted(igraph.Graph.De_Bruijn(m_, length).get_edgelist()))
    s_, length = g["words"][2], g["words"][3]
    check("kautz differs from igraph", sorted(tup(named["kautz"])) == sorted(igraph.Graph.Kautz(s_ - 1, length - 1).get_edgelist()))
    if g["named"]:
        covered("named graphs")
        exact("petersen", nx.petersen_graph())
        exact("heawood", nx.heawood_graph())
        exact("moebiusKantor", nx.moebius_kantor_graph())
        exact("pappus", nx.pappus_graph())
        exact("desargues", nx.desargues_graph())
        exact("dodecahedral", nx.dodecahedral_graph())
        exact("chvatal", nx.chvatal_graph())
        iso("icosahedral", nx.icosahedral_graph())
        iso("frucht", nx.frucht_graph())
        iso("tutte", nx.tutte_graph())
        iso("hoffmanSingleton", nx.hoffman_singleton_graph())
    return problems
