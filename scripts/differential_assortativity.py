"""The Assortativity section of scripts/differential.py: the library's answers
(Differential/Sources/GrafluentDifferential/Assortativity.swift) against NetworkX 3.7.

Directed cases are the case's digraph with its self-loops, which NetworkX reads as the library
does (a loop is one arc, once in each degree). Undirected cases drop their self-loops for the
measures whose loop conventions differ (NetworkX reads a loop once among a vertex's neighbors
but twice in its degree; the library twice in both): degree, attribute and numeric
assortativity, neighbor degrees and k_nn, the rich club (NetworkX refuses loops) and efficiency.
The histogram, regularity and the s-metric use the whole graph. Weights are the case's integers.

Compared: every degree assortativity pairing NetworkX offers (x, y in in/out; undirected), plain
and weighted; attribute assortativity of v mod 3 and numeric assortativity of 7v mod 11; average
neighbor degree for every source and target, plain and weighted; average degree connectivity
for source in or out (NetworkX's in+out follows successors only) and undirected; reciprocity
overall and per vertex on the loopless digraph; the triadic census; degree histograms; regularity;
the s-metric; the unnormalized rich club; global and local efficiency. Where the library answers
nil (no pairs, or a constant degree at one end), a model over the edge-end pairs here must agree
that the coefficient is undefined, since NetworkX's mixing-matrix sums can leave a rounding
residue in place of its NaN. Doubles agree within 1e-7.
"""

import math
import warnings

import networkx as nx

TOLERANCE = 1e-7
COVERED = {}


def covered(key, amount=1):
    COVERED[key] = COVERED.get(key, 0) + amount


def close(a, b, tol=TOLERANCE):
    return a is not None and b is not None and abs(a - b) <= tol * max(1.0, abs(b))


def defined(xs, ys):
    """Whether Pearson's r of these pairs is defined: some pair, and neither end constant."""
    return bool(xs) and len(set(xs)) > 1 and len(set(ys)) > 1


def compare_assortativity(case, mine):
    problems = []
    n, directed = case["n"], case["directed"]
    G = nx.DiGraph() if directed else nx.Graph()
    G.add_nodes_from(range(n))
    for u, v, w in case["edges"]:
        G.add_edge(u, v, weight=w)
    loopless = G.copy()
    loopless.remove_edges_from(list(nx.selfloop_edges(G)))
    H = G if directed else loopless
    for v in range(n):
        H.nodes[v]["class"] = v % 3
        H.nodes[v]["value"] = float((7 * v) % 11)
    names = {"in": "in", "out": "out"}

    def check_coefficient(key, ours, xs, ys, theirs):
        if ours is None:
            if defined(xs, ys):
                problems.append(f"{key}: library nil, NetworkX {theirs}")
            else:
                covered("coefficients undefined")
        elif not defined(xs, ys):
            problems.append(f"{key}: library {ours}, but the coefficient is undefined")
        elif not close(ours, theirs):
            problems.append(f"{key}: library {ours}, NetworkX {theirs}")
        else:
            covered("coefficients compared")

    def theirs_or_none(f):
        try:
            with_errors = f()
        except (ZeroDivisionError, ValueError, nx.NetworkXError):
            return None
        return None if with_errors is None or math.isnan(with_errors) else with_errors

    # Degree assortativity. NetworkX divides by a zero variance where the library answers nil.
    warnings.filterwarnings("ignore", category=RuntimeWarning)
    if directed:
        arcs = [(u, v) for u, v in G.edges()]
        for x in ("in", "out"):
            for y in ("in", "out"):
                for weighted in (False, True):
                    weight = "weight" if weighted else None
                    dx = dict(G.in_degree(weight=weight)) if x == "in" else dict(G.out_degree(weight=weight))
                    dy = dict(G.in_degree(weight=weight)) if y == "in" else dict(G.out_degree(weight=weight))
                    xs, ys = [dx[u] for u, _ in arcs], [dy[v] for _, v in arcs]
                    theirs = theirs_or_none(lambda: nx.degree_assortativity_coefficient(G, x=x, y=y, weight=weight))
                    table = mine["weightedDegree" if weighted else "degree"]
                    check_coefficient(f"degree {x}-{y}{' weighted' if weighted else ''}", table[f"{names[x]}-{names[y]}"], xs, ys, theirs)
        ends = arcs
    else:
        ends = [(u, v) for u, v in loopless.edges()] + [(v, u) for u, v in loopless.edges()]
        for weighted in (False, True):
            weight = "weight" if weighted else None
            d = dict(loopless.degree(weight=weight))
            xs, ys = [d[u] for u, _ in ends], [d[v] for _, v in ends]
            theirs = theirs_or_none(lambda: nx.degree_assortativity_coefficient(loopless, weight=weight))
            table = mine["weightedDegree" if weighted else "degree"]
            check_coefficient(f"degree{' weighted' if weighted else ''}", table["in+out-in+out"], xs, ys, theirs)
    # Attribute and numeric assortativity.
    classes = [(u % 3, v % 3) for u, v in ends]
    theirs = theirs_or_none(lambda: nx.attribute_assortativity_coefficient(H, "class"))
    ours = mine.get("attribute")
    one_class = not ends or all(a == b for a, b in classes) and len({a for a, _ in classes}) == 1
    if ours is None:
        if not one_class:
            problems.append(f"attribute: library nil, NetworkX {theirs}")
    elif one_class or not close(ours, theirs):
        problems.append(f"attribute: library {ours}, NetworkX {theirs}")
    values = [(float((7 * u) % 11), float((7 * v) % 11)) for u, v in ends]
    theirs = theirs_or_none(lambda: nx.numeric_assortativity_coefficient(H, "value"))
    check_coefficient("numeric", mine.get("numeric"), [a for a, _ in values], [b for _, b in values], theirs)

    # Neighbor degrees and k_nn.
    def vector(d):
        return [float(d[v]) for v in range(n)]

    pairings = [(s, t) for s in ("in", "out", "in+out") for t in ("in", "out", "in+out")] if directed else [("out", "out")]
    for s, t in pairings:
        key = f"{s}-{t}"
        for weighted in (False, True):
            weight = "weight" if weighted else None
            theirs = vector(nx.average_neighbor_degree(H, source=s, target=t, weight=weight))
            ours = mine["weightedAverageNeighborDegrees" if weighted else "averageNeighborDegrees"][key]
            if len(ours) != n or not all(close(a, b) for a, b in zip(ours, theirs)):
                problems.append(f"averageNeighborDegrees {key}{' weighted' if weighted else ''}: library {ours[:8]}, NetworkX {theirs[:8]}")
    connectivity = [(s, t) for s in ("in", "out") for t in ("in", "out", "in+out")] if directed else [("in+out", "in+out")]
    for s, t in connectivity:
        key = f"{s}-{t}"
        for weighted in (False, True):
            weight = "weight" if weighted else None
            theirs = nx.average_degree_connectivity(H, source=s, target=t, weight=weight)
            ours = {int(k): value for k, value in mine["weightedConnectivity" if weighted else "connectivity"][key]}
            if set(ours) != set(theirs) or not all(close(ours[k], theirs[k]) for k in ours):
                problems.append(f"averageDegreeConnectivity {key}{' weighted' if weighted else ''}: library {ours}, NetworkX {dict(theirs)}")

    if directed:
        # Reciprocity on the loopless digraph.
        if loopless.number_of_edges() == 0:
            if mine.get("reciprocity") is not None:
                problems.append(f"reciprocity: library {mine.get('reciprocity')}, no arcs")
        elif not close(mine.get("reciprocity"), nx.overall_reciprocity(loopless), 1e-12):
            problems.append(f"reciprocity: library {mine.get('reciprocity')}, NetworkX {nx.overall_reciprocity(loopless)}")
        theirs = nx.reciprocity(loopless, list(range(n)))
        ours = mine["vertexReciprocity"]
        for v in range(n):
            if (ours[v] is None) != (theirs[v] is None) or (ours[v] is not None and not close(ours[v], theirs[v], 1e-12)):
                problems.append(f"reciprocity of {v}: library {ours[v]}, NetworkX {theirs[v]}")
                break
        census = nx.triadic_census(G)
        expected = [census[k] for k in ("003", "012", "102", "021D", "021U", "021C", "111D", "111U", "030T", "030C", "201", "120D", "120U", "120C", "210", "300")]
        if mine["census"] != expected:
            problems.append(f"triadicCensus: library {mine['census']}, NetworkX {expected}")
        covered("censuses compared")

        def histogram(degrees):
            top = max(degrees, default=-1)
            return [sum(1 for d in degrees if d == k) for k in range(top + 1)]

        if mine["inHistogram"] != histogram([d for _, d in G.in_degree()]):
            problems.append(f"inDegreeHistogram: library {mine['inHistogram']}")
        if mine["outHistogram"] != histogram([d for _, d in G.out_degree()]):
            problems.append(f"outDegreeHistogram: library {mine['outHistogram']}")
        if mine["isRegular"] != nx.is_regular(G):
            problems.append(f"isRegular: library {mine['isRegular']}, NetworkX {nx.is_regular(G)}")
        return problems

    if mine["histogram"] != nx.degree_histogram(G):
        problems.append(f"degreeHistogram: library {mine['histogram']}, NetworkX {nx.degree_histogram(G)}")
    if mine["isRegular"] != nx.is_regular(G):
        problems.append(f"isRegular: library {mine['isRegular']}, NetworkX {nx.is_regular(G)}")
    if mine["sMetric"] != nx.s_metric(G):
        problems.append(f"sMetric: library {mine['sMetric']}, NetworkX {nx.s_metric(G)}")
    rich = nx.rich_club_coefficient(loopless, normalized=False)
    expected = [rich[k] for k in sorted(rich)]
    if sorted(rich) != list(range(len(rich))) or len(mine["richClub"]) != len(expected) or not all(close(a, b, 1e-12) for a, b in zip(mine["richClub"], expected)):
        problems.append(f"richClubCoefficients: library {mine['richClub']}, NetworkX {expected}")
    for key, theirs in (("globalEfficiency", nx.global_efficiency(loopless)), ("localEfficiency", nx.local_efficiency(loopless))):
        if not close(mine[key], theirs, 1e-12):
            problems.append(f"{key}: library {mine[key]}, NetworkX {theirs}")
    covered("undirected compared")
    return problems
