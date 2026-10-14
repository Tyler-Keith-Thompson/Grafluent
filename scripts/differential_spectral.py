"""The spectral section of scripts/differential.py: SpectralGraphTheory against NetworkX, scipy and
numpy.

* `compare_spectral(case, mine)`, weights |w|, on the undirected multigraph of the case's edges (a
  directed case's arcs as edges, loops kept):
  - the k = min(3, n) extreme eigenpairs (L smallest and largest, N smallest, A largest and
    smallest, Q largest) against `scipy.linalg.eigh` of the matrices built here from their
    definitions (a loop adding 2w to A[v][v], as the library does), and those matrices against
    NetworkX's `laplacian_matrix`, `normalized_laplacian_matrix` and `adjacency_matrix` on loopless
    cases (NetworkX adds a loop once); eigenvalues to 1e-6 relative, each eigenvector up to sign:
    its projection on the reference eigenspace of its eigenvalue (eigenvalues within 1e-3 of the
    scale grouped) of norm 1 to 1e-4;
  - both incidence matrices against `incidence_matrix(oriented=)` exactly, loops apart (NetworkX
    gives a loop an empty column; the library 2 unoriented, nothing oriented);
  - the modularity matrix against `modularity_matrix` on loopless cases, against A − k kᵀ / vol
    otherwise (n ≤ 60);
  - hitting times both ways and the commute time against a dense solve of (I − P) h = 1 on the
    target's component;
  - on a directed case, the stationary distribution against the lazy walk's limit from the uniform
    distribution (repeated squaring of (I + P)/2), and against `pagerank(alpha=1)` where the
    chain has a unique stationary distribution; the oriented incidence matrix against
    `incidence_matrix(oriented=True)`; the directed modularity matrix against
    `directed_modularity_matrix` (n ≤ 60, total weight positive).
"""

import networkx as nx
import numpy as np
import scipy.linalg

COVERED = {"eigenpairs": 0, "eigenvectors in multiple eigenspaces": 0, "hitting times": 0,
           "stationary": 0, "stationary unique (pagerank)": 0, "incidence loops": 0}


def matrices(n, edges, weights):
    """A (a loop 2w), L = D − A with loops cancelling, N, Q = D + A."""
    a = np.zeros((n, n))
    for (u, v), w in zip(edges, weights):
        a[u, v] += w
        if u != v:
            a[v, u] += w
        else:
            a[u, u] += w
    d = a.sum(axis=1)
    loops = np.diag(np.diag(a))
    dl = d - np.diag(a)
    lap = np.diag(dl) - (a - loops)
    root = np.where(d > 0, 1 / np.sqrt(np.where(d > 0, d, 1)), 0)
    nl = root[:, None] * lap * root[None, :]
    return a, lap, nl, np.diag(d) + a


def compare_eigenpairs(n, mine, mats, problems):
    a, lap, nl, q = mats
    k = min(3, n)
    if "error" in mine["eigenvalues"]:
        problems.append(f"eigenpairs threw NoConvergence {mine['eigenvalues']['error']}")
        return
    for key, matrix, smallest in [("L-", lap, True), ("L+", lap, False), ("N-", nl, True), ("A+", a, False), ("A-", a, True), ("Q+", q, False)]:
        values, vectors = scipy.linalg.eigh(matrix)
        order = list(range(n)) if smallest else list(range(n - 1, -1, -1))
        scale = max(1.0, float(np.max(np.abs(values)))) if n else 1.0
        ours = mine["eigenvalues"][key]
        flat = mine["eigenvectors"][key]
        if len(ours) != k:
            problems.append(f"{key}: {len(ours)} eigenpairs for {k}")
            continue
        COVERED["eigenpairs"] += k
        for i in range(k):
            expected = values[order[i]]
            if abs(ours[i] - expected) > 1e-6 * max(abs(expected), 1e-3 * scale) + 1e-10 * scale * n:
                problems.append(f"{key} eigenvalue {i}: library {ours[i]}, scipy {expected}")
                continue
            x = np.array(flat[i * n:(i + 1) * n])
            cluster = [j for j in range(n) if abs(values[j] - ours[i]) <= 1e-3 * scale]
            if len(cluster) > 1:
                COVERED["eigenvectors in multiple eigenspaces"] += 1
            if not cluster:
                problems.append(f"{key} eigenvalue {i}: no reference eigenvalue near {ours[i]}")
                continue
            projection = np.linalg.norm(vectors[:, cluster].T @ x)
            if abs(projection - 1) > 1e-4 or abs(np.linalg.norm(x) - 1) > 1e-9:
                problems.append(f"{key} eigenvector {i}: projection on the reference eigenspace {projection}")


def compare_spectral(case, mine):
    problems = []
    if mine is None:
        return ["no spectral answers"]
    n = case["n"]
    edges = [(u, v) for u, v, _ in case["edges"]]
    weights = [float(abs(w)) for _, _, w in case["edges"]]
    loops = any(u == v for u, v in edges)
    mats = matrices(n, edges, weights)
    a = mats[0]
    if not loops and not case["directed"]:
        # The definitions against NetworkX's matrices.
        G = nx.Graph()
        G.add_nodes_from(range(n))
        G.add_weighted_edges_from((u, v, w) for (u, v), w in zip(edges, weights))
        for name, ours, theirs in [("A", mats[0], nx.adjacency_matrix(G, nodelist=range(n)).toarray()),
                                   ("L", mats[1], nx.laplacian_matrix(G, nodelist=range(n)).toarray()),
                                   ("N", mats[2], nx.normalized_laplacian_matrix(G, nodelist=range(n)).toarray())]:
            if not np.allclose(ours, theirs, rtol=1e-12, atol=1e-12):
                problems.append(f"the reference {name} differs from NetworkX's")
    if n > 0:
        compare_eigenpairs(n, mine, mats, problems)

    # Incidence matrices.
    M = nx.MultiGraph()
    M.add_nodes_from(range(n))
    M.add_edges_from(edges)
    for key, oriented in (("incidence", False), ("orientedIncidence", True)):
        ours = np.array(mine[key]).reshape(n, len(edges))
        theirs = nx.incidence_matrix(M, nodelist=range(n), edgelist=edges, oriented=oriented).toarray() if edges else np.zeros((n, 0))
        for j, (u, v) in enumerate(edges):
            if u == v:
                COVERED["incidence loops"] += 1
                expected = np.zeros(n)
                if not oriented:
                    expected[u] = 2
                if not np.array_equal(ours[:, j], expected):
                    problems.append(f"{key}: loop column {j} is {ours[:, j].tolist()}")
            elif not np.array_equal(ours[:, j], theirs[:, j]):
                problems.append(f"{key}: column {j} is {ours[:, j].tolist()}, NetworkX {theirs[:, j].tolist()}")
                break

    # The modularity matrix.
    if mine.get("modularity") is not None:
        ours = np.array(mine["modularity"])
        k = a.sum(axis=1)
        volume = k.sum()
        if not loops and volume > 0 and not case["directed"]:
            G = nx.Graph()
            G.add_nodes_from(range(n))
            G.add_weighted_edges_from((u, v, w) for (u, v), w in zip(edges, weights))
            theirs = np.asarray(nx.modularity_matrix(G, nodelist=range(n), weight="weight"))
        else:
            theirs = a - np.outer(k, k) / volume if volume > 0 else a
        if not np.allclose(ours, theirs, rtol=1e-12, atol=1e-12 * max(1.0, volume)):
            problems.append("modularityMatrix differs")

    # Hitting and commute times.
    s, t = case["sources"][0], case["target"]
    reach = nx.node_connected_component(nx.Graph([(u, v) for (u, v), w in zip(edges, weights) if w > 0] + [(t, t)]), t)
    if s == t:
        expected = (0.0, 0.0)
    elif s not in reach:
        expected = None
    else:
        d = a.sum(axis=1)

        def hit(source, target):
            members = sorted(reach - {target})
            index = {v: i for i, v in enumerate(members)}
            system = np.array([[(d[u] - a[u, u] if u == v else -a[u, v]) for v in members] for u in members])
            h = np.linalg.solve(system, np.array([d[u] for u in members]))
            return h[index[source]]
        expected = (hit(s, t), hit(t, s))
    ours = (mine.get("hitting"), mine.get("hittingBack"))
    if expected is None:
        if ours != (None, None) or mine.get("commute") is not None:
            problems.append(f"hitting times {ours} across components")
    else:
        COVERED["hitting times"] += 1
        for name, value, reference in (("hittingTime", ours[0], expected[0]), ("hittingTime back", ours[1], expected[1]), ("commuteTime", mine.get("commute"), expected[0] + expected[1])):
            if value is None or abs(value - reference) > 1e-6 * max(1.0, reference):
                problems.append(f"{name}: library {value}, reference {reference}")

    if case["directed"]:
        problems += compare_directed(case, mine, n, edges, weights)
    return problems


def compare_directed(case, mine, n, edges, weights):
    problems = []
    arcs = np.zeros((n, n))
    for (u, v), w in zip(edges, weights):
        arcs[u, v] += w
    out = arcs.sum(axis=1)
    p = np.where(out[:, None] > 0, arcs / np.where(out > 0, out, 1)[:, None], 1.0 / n)
    if mine.get("stationaryFailed"):
        problems.append("stationaryDistribution threw NoConvergence")
    elif n > 0:
        COVERED["stationary"] += 1
        lazy = (np.eye(n) + p) / 2
        for _ in range(40):
            lazy = lazy @ lazy
            lazy /= lazy.sum(axis=1, keepdims=True)
        expected = np.full(n, 1.0 / n) @ lazy
        ours = np.array(mine["stationary"])
        if np.abs(ours - expected).sum() > 1e-8:
            problems.append(f"stationaryDistribution: L1 distance {np.abs(ours - expected).sum()} from the lazy walk's limit")
        # Unique when 1 is a simple eigenvalue of P.
        if np.linalg.matrix_rank(p.T - np.eye(n), tol=1e-9) == n - 1:
            D = nx.DiGraph()
            D.add_nodes_from(range(n))
            D.add_weighted_edges_from((u, v, w) for (u, v), w in zip(edges, weights) if w > 0)
            try:
                rank = nx.pagerank(D, alpha=1.0, tol=1e-13, max_iter=100000)
                theirs = np.array([rank[v] for v in range(n)])
                COVERED["stationary unique (pagerank)"] += 1
                if np.abs(ours - theirs).sum() > 1e-7:
                    problems.append(f"stationaryDistribution: L1 distance {np.abs(ours - theirs).sum()} from pagerank(alpha=1)")
            except nx.PowerIterationFailedConvergence:
                pass
    M = nx.MultiDiGraph()
    M.add_nodes_from(range(n))
    M.add_edges_from(edges)
    ours = np.array(mine["directedIncidence"]).reshape(n, len(edges))
    theirs = nx.incidence_matrix(M, nodelist=range(n), edgelist=edges, oriented=True).toarray() if edges else np.zeros((n, 0))
    if not np.array_equal(ours, theirs):
        problems.append("directed incidenceMatrix(oriented: true) differs from NetworkX's")
    if mine.get("directedModularity") is not None:
        total = arcs.sum()
        ours = np.array(mine["directedModularity"])
        if total > 0:
            D = nx.DiGraph()
            D.add_nodes_from(range(n))
            D.add_weighted_edges_from((u, v, w) for (u, v), w in zip(edges, weights))
            theirs = np.asarray(nx.directed_modularity_matrix(D, nodelist=range(n), weight="weight"))
        else:
            theirs = arcs
        if not np.allclose(ours, theirs, rtol=1e-12, atol=1e-12 * max(1.0, total)):
            problems.append("directed modularityMatrix differs from NetworkX's")
    return problems
