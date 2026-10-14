"""The drawing section of scripts/differential.py.

GraphDrawing against NetworkX's layout module on the case's edges as an undirected multigraph
(Differential/Sources/GrafluentDifferential/GraphDrawing.swift): shell_layout with one shell and
with the shells [[0], the rest] (NetworkX computes the angles in single precision, so within
1e-6), spiral_layout in both modes and bipartite_layout with the even vertices on the left
(within 1e-9; each side's points as a set, since NetworkX orders a side by Python set iteration); spectral_layout up to the sign of each axis, when the second, third and fourth
Laplacian eigenvalues are apart by 1e-6; python-igraph's layout_mds on connected cases up to a rigid
motion (the drawings' distances), when the three largest eigenvalues of the doubly centred squared distances are
apart by 1e-6; and the planar layout present exactly when check_planarity says so, drawn without a
crossing.
"""

import igraph
import networkx as nx
import numpy as np

COVERED = {"shell, spiral, bipartite": 0, "spectral compared": 0, "scaling compared": 0, "planar drawn": 0}


def close(a, b, tolerance):
    return len(a) == len(b) and all(abs(x - y) <= tolerance for p, q in zip(a, b) for x, y in zip(p, q))


def up_to_signs(a, b, tolerance):
    return any(close([[sx * x, sy * y] for x, y in a], b, tolerance) for sx in (1, -1) for sy in (1, -1))


def compare_drawing(case, mine):
    if mine is None:
        return ["no drawing answers"]
    n = case["n"]
    problems = []
    M = nx.MultiGraph()
    M.add_nodes_from(range(n))
    M.add_edges_from((u, v) for u, v, _ in case["edges"])
    if n == 0:
        return problems
    rows = lambda pos: [[float(pos[v][0]), float(pos[v][1])] for v in range(n)]
    if not close(mine["shell"], rows(nx.shell_layout(M)), 1e-6):
        problems.append(f"shellLayout(): library {mine['shell']}, NetworkX {rows(nx.shell_layout(M))}")
    theirs = rows(nx.shell_layout(M, nlist=[[0], list(range(1, n))]))
    if not close(mine["shellCentred"], theirs, 1e-6):
        problems.append(f"shellLayout(shells: [[0], rest]): library {mine['shellCentred']}, NetworkX {theirs}")
    for key, equidistant in [("spiral", False), ("spiralEquidistant", True)]:
        theirs = rows(nx.spiral_layout(M, equidistant=equidistant))
        if not close(mine[key], theirs, 1e-9):
            problems.append(f"spiralLayout(equidistant: {equidistant}).rescaled(): library {mine[key]}, NetworkX {theirs}")
    # NetworkX places each side in the iteration order of a Python set, which need not be the
    # order given; the library takes the order given. So the points are compared as a set per
    # side, and the library's are checked to rise in the order given.
    theirs = rows(nx.bipartite_layout(M, nodes=list(range(0, n, 2))))
    for side in (0, 1):
        ours = [mine["bipartite"][v] for v in range(side, n, 2)]
        if not close(sorted(ours), sorted(theirs[v] for v in range(side, n, 2)), 1e-9) or ours != sorted(ours, key=lambda p: p[1]):
            problems.append(f"bipartiteLayout(left: evens).rescaled() side {side}: library {ours}, NetworkX {[theirs[v] for v in range(side, n, 2)]}")
    COVERED["shell, spiral, bipartite"] += 1
    if mine.get("spectral") is None or mine.get("scaling") is None:
        problems.append("spectralLayout or multidimensionalScalingLayout threw NoConvergence")
        return problems
    if n >= 4:
        A = nx.to_numpy_array(M)
        np.fill_diagonal(A, 0)
        w = np.linalg.eigvalsh(np.diag(A.sum(axis=1)) - A)
        if w[2] - w[1] > 1e-6 and w[3] - w[2] > 1e-6 and w[1] - w[0] > 1e-6:
            theirs = rows(nx.spectral_layout(M))
            mine_rescaled = np.array(mine["spectral"])
            mine_rescaled -= mine_rescaled.mean(axis=0)
            mine_rescaled /= np.abs(mine_rescaled).max()
            if not up_to_signs(mine_rescaled.tolist(), theirs, 1e-6):
                problems.append(f"spectralLayout().rescaled(): library {mine_rescaled.tolist()}, NetworkX {theirs} (up to signs)")
            COVERED["spectral compared"] += 1
    U = nx.Graph(M)
    U.remove_edges_from(nx.selfloop_edges(U))
    if n >= 3 and nx.is_connected(U):
        D = np.array(nx.floyd_warshall_numpy(U))
        J = np.eye(n) - np.ones((n, n)) / n
        w = np.linalg.eigvalsh(-0.5 * J @ (D * D) @ J)
        if w[-1] - w[-2] > 1e-6 and w[-2] - w[-3] > 1e-6 and w[-2] > 1e-6:
            g = igraph.Graph(n=n, edges=list(U.edges()))
            theirs = np.array(g.layout_mds(dim=2).coords)
            ours = np.array(mine["scaling"])
            # igraph's axes may come rotated: compare the drawings' distances.
            gap = np.abs(np.linalg.norm(ours[:, None] - ours[None], axis=-1) - np.linalg.norm(theirs[:, None] - theirs[None], axis=-1)).max()
            if gap > 1e-6 * max(1.0, float(D.max())):
                problems.append(f"multidimensionalScalingLayout(): library {ours.tolist()}, igraph layout_mds {theirs.tolist()} (distances differ by {gap})")
            COVERED["scaling compared"] += 1
    planar, _ = nx.check_planarity(U)
    if mine["planar"] != planar:
        problems.append(f"planarLayout() present {mine['planar']}, NetworkX check_planarity {planar}")
    if mine["planar"]:
        COVERED["planar drawn"] += 1
        if not mine["planarValid"]:
            problems.append("planarLayout(): a crossing, a vertex on an edge, a shared point or a point off the grid")
    return problems
