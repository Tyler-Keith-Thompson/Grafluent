"""The Flows section of scripts/differential.py.

Two parts:

* `replay_catalog`: every row of Tests/Catalogs/Flows/cases.md, parsed from its Input and Call
  columns, answered by the library (`GrafluentDifferential flows-catalog`, one batch) and rendered
  in the catalog's notation, must equal the Expected column; "(one of several optima)" rows
  compare the cost and check the flow and its certificate instead. Trap rows run one per process
  and must crash.
* `flow_case` / `compare_flows`: on every random case, a multigraph flow network (the case's
  edges with capacity |w| and cost w, then a parallel copy of every fourth edge, reversed when
  undirected) is answered by the library and checked against NetworkX, igraph and the reference
  models of Tests/Catalogs/Flows/ref.py (Edmonds–Karp's pinned flow, the components rule of the
  undirected global cut, Even's vertex cut), with size limits where the
  Python models are slow. Every flow, cut and cost answer is also validated on its own:
  capacity and conservation, the cut's edges and value from its sides, the cost from the flow,
  the potentials' optimality certificate, and every disjoint path.
"""

import importlib.util
import json
import os
import subprocess

import networkx as nx
import igraph

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "Tests", "Catalogs", "Flows")

_spec = importlib.util.spec_from_file_location("flows_ref", os.path.join(CATALOG, "ref.py"))
REF = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(REF)

COVERED = {}


def covered(key, amount=1):
    COVERED[key] = COVERED.get(key, 0) + amount


# ---------------------------------------------------------------------------------------------
# The catalog


def parse_label(text):
    return int(text) if text.lstrip("-").isdigit() else text


def parse_value(text, ctype):
    if ctype == "Double":
        return float(text)
    return int(text)


def split_items(text):
    return [x for x in text.split(", ") if x] if text else []


def generator(token):
    """A generator token of the catalog's notation, through ref.py's own generators."""
    name, args = token.split("(", 1)
    args = args.rstrip(")")
    if name == "nx":
        return REF.named(args)
    values = [int(x) for x in args.split(",")]
    table = {
        "lcgnet": REF.lcgnet, "lcgund": REF.lcgund, "lcgcost": REF.lcgcost,
        "K": REF.K, "C": REF.C, "P": REF.P, "grid": REF.grid, "Kb": REF.Kb, "wheel": REF.wheel,
        "Q": REF.hypercube,
    }
    if name in ("Kd", "Cd", "Pd"):
        return {"Kd": REF.K, "Cd": REF.C, "Pd": REF.P}[name](*values, directed=True)
    return table[name](*values)


def parse_network(text):
    """A ref.Net from the Input column."""
    supply = None
    if "; supply [" in text:
        text, rest = text.split("; supply [", 1)
        supply = rest[: rest.rindex("]")]
    ctype, directed = "Int", True
    for prefix in ("Double", "Int8", "UInt8"):
        if text.startswith(prefix + " "):
            ctype = prefix
            text = text[len(prefix) + 1:]
    if text.startswith("undirected "):
        directed = False
        text = text[len("undirected "):]
    if text.startswith("V ["):
        vpart, epart = text.split("]; E [", 1)
        labels = [parse_label(x) for x in split_items(vpart[len("V ["):])]
        epart = epart[: epart.rindex("]")]
        edges, caps, costs = [], [], []
        for item in split_items(epart):
            parts = item.split(" ")
            arrow = "→" if "→" in parts[0] else "–"
            u, v = parts[0].split(arrow)
            edges.append((parse_label(u), parse_label(v)))
            cap = [p for p in parts[1:] if not p.startswith("@")]
            cost = [p for p in parts[1:] if p.startswith("@")]
            caps.append(parse_value(cap[0], ctype) if cap else 1)
            if cost:
                costs.append(int(cost[0][1:]))
        net = REF.Net(labels, edges, caps, costs or None, directed=directed, ctype=ctype)
    else:
        net = generator(text)
        net.ctype = ctype
    if supply is not None:
        sup = [0] * net.n
        for item in split_items(supply):
            k, b = item.split(": ")
            sup[net.index[parse_label(k)]] = int(b)
        net.supply = sup
    return net


def parse_call(text):
    """(name, from label, to label) of the Call column."""
    text = text.strip("`")
    name, args = text.split("(", 1)
    frm = to = None
    if args.startswith("from: "):
        a, b = args[len("from: "):].split(", to: ", 1)
        frm, to = parse_label(a), parse_label(b.split(",")[0].rstrip(")"))
    return name, frm, to


def catalog_rows():
    rows = []
    with open(os.path.join(CATALOG, "cases.md")) as f:
        for line in f:
            if line.startswith("| FL-"):
                cells = line.rstrip("\n").strip().strip("|").split(" | ")
                rows.append([c.strip() for c in cells])
    return rows


def request(net, name, frm, to):
    def number(label):
        if label is None:
            return None
        return net.index[label] if label in net.index else label

    caps = net.caps()
    return {
        "ctype": net.ctype, "directed": net.directed, "n": net.n, "edges": [[u, v] for u, v in net.E],
        "capacities": [REF.fmtv(c) if not isinstance(c, float) else repr(c) for c in caps],
        "costs": net.cost, "supply": net.supply, "call": name, "from": number(frm), "to": number(to),
    }


def render(group, net, ans):
    """The library's answer in the catalog's notation."""
    if ans["isNil"]:
        return "nil"
    lab = net.lab
    if group in ("MaximumFlow", "Dinic", "MinimumCut", "GlobalMinimumCut", "DirectedGlobalMinimumCut", "EdmondsKarp"):
        T = set(ans["sink"])
        S = set(range(net.n)) - T
        flow = f"flow {REF.fmtl(ans['flows'])}; " if group == "EdmondsKarp" else ""
        return f"value {ans['value']}; {flow}S {REF.lab_list(net, S)}; T {REF.lab_list(net, T)}; cut {REF.fmtl(ans['cutEdges'])}"
    if group == "MaximumFlowValue":
        return ans["value"]
    if group == "GomoryHu":
        return "edges " + REF.fmtl(f"{lab(int(u))}–{lab(int(p))} {c}" for u, p, c in ans["tree"])
    if group == "MinimumCostFlow":
        return f"cost {ans['cost']}; flow {REF.fmtl(ans['flows'])}"
    if group == "MinimumCostMaximumFlow":
        return f"value {ans['value']}; cost {ans['cost']}; flow {REF.fmtl(ans['flows'])}"
    if group in ("EdgeConnectivity", "VertexConnectivity"):
        return str(ans["integer"])
    if group in ("EdgeDisjointPaths", "VertexDisjointPaths"):
        return REF.paths_word(ans["integer"])
    if group == "MinimumVertexCut":
        return REF.fmtl(lab(v) for v in ans["vertices"])
    raise ValueError(group)


def path_problems(tag, net, s, t, paths, vertex_disjoint):
    """Each path from s to t along its edges (`3r`: an undirected edge against its stored order),
    repeating no vertex; no edge, or no inner vertex when `vertex_disjoint`, in two paths."""
    problems = []
    used_edges, used_inner = set(), set()
    for path in paths:
        vs, es = path["vertices"], path["edges"]
        if not vs or vs[0] != s or vs[-1] != t or len(vs) != len(es) + 1 or len(set(vs)) != len(vs):
            problems.append(f"{tag}: {vs} is not a path from {s} to {t}")
            continue
        for i, name in enumerate(es):
            k = int(name.rstrip("r"))
            u, v = net.E[k]
            if name.endswith("r"):
                u, v = v, u
            if (u, v) != (vs[i], vs[i + 1]) or u == v:
                problems.append(f"{tag}: edge {name} does not join {vs[i]} to {vs[i + 1]}")
            if k in used_edges:
                problems.append(f"{tag}: edge {k} in two paths")
            used_edges.add(k)
        if vertex_disjoint:
            for x in vs[1:-1]:
                if x in used_inner:
                    problems.append(f"{tag}: vertex {x} in two paths")
                used_inner.add(x)
    return problems


def cost_problems(tag, arcs, supply, flows, cost, potentials=None):
    """Capacity, conservation with the supplies, the cost from the flow, and (when given) the
    potentials' certificate. `arcs` are (u, v, capacity, cost)."""
    problems = []
    balance = list(supply)
    total = 0
    for (u, v, c, w), f in zip(arcs, flows):
        if not 0 <= f <= c:
            problems.append(f"{tag}: flow {f} outside [0, {c}]")
        balance[u] -= f
        balance[v] += f
        total += f * w
    if any(balance):
        problems.append(f"{tag}: supplies not met {balance[:12]}")
    if total != cost:
        problems.append(f"{tag}: cost {cost}, but the flow costs {total}")
    if potentials is not None:
        for (u, v, c, w), f in zip(arcs, flows):
            if u == v:
                if (w < 0 and f != c) or (w > 0 and f != 0):
                    problems.append(f"{tag}: self-loop of cost {w} carries {f} of {c}")
                continue
            reduced = w + potentials[u] - potentials[v]
            if (f < c and reduced < 0) or (f > 0 and reduced > 0):
                problems.append(f"{tag}: arc {u}->{v} flow {f}/{c} has reduced cost {reduced}")
                break
    return problems


def replay_catalog(executable):
    """Replays every catalog row; returns the problems found."""
    rows = catalog_rows()
    batch, expected, traps = [], [], []
    for row in rows:
        ident, group, _, inp, call, exp = row[:6]
        net = parse_network(inp)
        name, frm, to = parse_call(call)
        req = request(net, name, frm, to)
        if exp.startswith("trap"):
            traps.append((ident, req))
        else:
            batch.append(req)
            expected.append((ident, group, net, exp, call))
    problems = []
    run = subprocess.run([executable, "flows-catalog"], input=json.dumps(batch), capture_output=True, text=True, timeout=120)
    if run.returncode != 0:
        return [f"catalog: the library crashed: {run.stderr.strip()[-800:]}"]
    for (ident, group, net, exp, call), ans in zip(expected, json.loads(run.stdout)):
        if group in ("GlobalMinimumCut", "DirectedGlobalMinimumCut") and exp.endswith(" (one of several minimum cuts)"):
            # Not pinned: the value, and the cut checked from its own sides.
            cut = {"value": ans["value"], "sink": ans["sink"], "edges": ans["cutEdges"]}
            problems += cut_problems(ident, net, cut)
            if not net.directed and 0 in ans["sink"]:
                problems.append(f"{ident}: the first vertex is on the sink side")
            mine = f"value {ans['value']} (one of several minimum cuts)"
            if mine != exp:
                problems.append(f"{ident}: expected {exp}, library {mine}")
            continue
        if group in ("EdgeDisjointPaths", "VertexDisjointPaths"):
            _, frm, to = parse_call(call)
            problems += path_problems(ident, net, net.index[frm], net.index[to], ans["paths"], group == "VertexDisjointPaths")
        several = exp.endswith(" (one of several optima)")
        if several:
            exp = exp[: -len(" (one of several optima)")]
        if not ans["isNil"] and group in ("MinimumCostFlow", "MinimumCostMaximumFlow"):
            if ans["integer"] != 1:
                problems.append(f"{ident}: the potentials are not an optimality certificate")
            arcs = [(u, v, c, w) for (u, v), c, w in zip(net.E, net.caps(), net.cost or [])]
            if group == "MinimumCostFlow":
                supply = net.supply
            else:
                _, frm, to = parse_call(call)
                supply = [0] * net.n
                supply[net.index[frm]] += int(ans["value"])
                supply[net.index[to]] -= int(ans["value"])
            problems += cost_problems(ident, arcs, supply, [int(x) for x in ans["flows"]], ans["cost"])
        mine = render(group, net, ans)
        if several:
            head = exp.split("; flow ")[0]
            if mine.split("; flow ")[0] != head:
                problems.append(f"{ident}: expected {head}, library {mine.split('; flow ')[0]}")
        elif mine != exp:
            problems.append(f"{ident}: expected {exp}, library {mine}")
    crashed = 0
    for ident, req in traps:
        try:
            one = subprocess.run([executable, "flows-catalog"], input=json.dumps([req]), capture_output=True, text=True, timeout=20)
            if one.returncode == 0:
                problems.append(f"{ident}: expected a trap, the library returned {one.stdout[:200]}")
            else:
                crashed += 1
        except subprocess.TimeoutExpired:
            problems.append(f"{ident}: expected a trap, the library did not finish")
    print(f"flows catalog: {len(batch)} rows answered, {crashed} of {len(traps)} traps trapped, {len(problems)} problem(s)")
    return problems


# ---------------------------------------------------------------------------------------------
# Random cases


def flow_case(case):
    """The flow network for a case: edges [u, v, capacity, cost], supplies, a source and a sink.
    Derived from the case alone (no random draws), so seeds stay reproducible."""
    n = case["n"]
    edges = [[u, v, abs(w), w] for u, v, w in case["edges"]]
    for i, (u, v, w) in enumerate(case["edges"]):
        if i % 4 == 0:
            a, b = (u, v) if case["directed"] else (v, u)
            edges.append([a, b, (abs(w) * 7 + 3) % 13, abs(w) % 7 - 2])
    s = case["sources"][0]
    t = case["target"] if case["target"] != s else (s + 1) % n
    supply = [0] * n
    if n >= 2:
        b = (n + len(edges)) % 4 + 1
        supply[s] += b
        supply[t] -= b
        if len(case["sources"]) > 1 and n > 2:
            supply[case["sources"][1]] += 2
            supply[(t + 1) % n] -= 2
    return {"edges": edges, "supply": supply, "source": s, "sink": t}


def flow_net(case):
    f = case["flow"]
    return REF.Net(range(case["n"]), [(e[0], e[1]) for e in f["edges"]], [e[2] for e in f["edges"]],
                   [e[3] for e in f["edges"]], f["supply"], directed=case["directed"])


def ig_multigraph(net):
    """igraph's graph with every non-loop edge, parallel copies kept."""
    return igraph.Graph(n=net.n, edges=[(u, v) for u, v in net.E if u != v], directed=net.directed)


def ig_simple(net):
    seen, edges = set(), []
    for u, v in net.E:
        if u == v:
            continue
        key = (u, v) if net.directed else (min(u, v), max(u, v))
        if key not in seen:
            seen.add(key)
            edges.append(key)
    return igraph.Graph(n=net.n, edges=edges, directed=net.directed)


def cut_problems(tag, net, cut, T=None, value=None):
    """The cut's edges and value from its own sides, and (when given) its sink side and value."""
    problems = []
    mine = set(cut["sink"])
    if T is not None and mine != T:
        problems.append(f"{tag}: sink side {sorted(mine)[:12]}, reference {sorted(T)[:12]}")
    if cut["edges"] != REF.cut_edges(net, mine):
        problems.append(f"{tag}: cut edges {cut['edges'][:12]} are not the edges from S to T {REF.cut_edges(net, mine)[:12]}")
    number = float if net.ctype == "Double" else int
    if number(cut["value"]) != REF.cut_value(net, set(range(net.n)) - mine):
        problems.append(f"{tag}: cut value {cut['value']} is not the capacity of its edges")
    if value is not None and number(cut["value"]) != value:
        problems.append(f"{tag}: cut value {cut['value']}, reference {value}")
    return problems


def flow_problems(tag, net, s, t, flows, value):
    problems = []
    balance = [0] * net.n
    for e, ((u, v), c) in enumerate(zip(net.E, net.caps())):
        f = flows[e]
        if u == v and f != 0:
            problems.append(f"{tag}: self-loop {e} carries {f}")
        if net.directed and not 0 <= f <= c or not net.directed and not -c <= f <= c:
            problems.append(f"{tag}: flow {f} on edge {e} exceeds {c}")
        balance[u] -= f
        balance[v] += f
    for x in range(net.n):
        if x not in (s, t) and balance[x]:
            problems.append(f"{tag}: conservation fails at {x}")
            break
    if balance[t] != value or balance[s] != -value:
        problems.append(f"{tag}: the flow's balance {balance[t]} is not its value {value}")
    return problems


def nx_min_cost(arcs, supply):
    """NetworkX network_simplex's cost, or None when infeasible."""
    G = nx.MultiDiGraph()
    G.add_nodes_from(range(len(supply)))
    for x, b in enumerate(supply):
        G.nodes[x]["demand"] = -b
    for u, v, c, w in arcs:
        G.add_edge(u, v, capacity=c, weight=w)
    try:
        cost, _ = nx.network_simplex(G)
        return cost
    except nx.NetworkXUnfeasible:
        return None


def compare_flows(case, mine):
    problems = []
    n, directed = case["n"], case["directed"]
    f = case["flow"]
    net = flow_net(case)
    m = net.m
    s, t = f["source"], f["sink"]
    # Arcs of the minimum-cost problem: the digraph itself, or `directed` of an undirected one.
    arcs = []
    for u, v, c, w in f["edges"]:
        arcs.append((u, v, c, w))
        if not directed:
            arcs.append((v, u, c, w))
    if not mine["consistent"]:
        problems.append("flows: equal-by-definition answers differ inside the library")

    if s != t:
        G = REF.nx_flow_graph(net)
        value = nx.maximum_flow_value(G, s, t)
        _, (_, sink) = nx.minimum_cut(G, s, t)
        T = set(sink)
        iv = REF.ig_graph(net).maxflow(s, t, capacity=[float(c) for c in net.caps()]).value
        if abs(iv - value) > 1e-9:
            problems.append(f"references disagree: NetworkX {value}, igraph {iv}")
        covered("flows compared")
        covered("flow value 0", value == 0)
        for name in ("maximum", "edmondsKarp", "dinic"):
            answer = mine[name]
            if int(answer["value"]) != value:
                problems.append(f"{name}: value {answer['value']}, NetworkX {value}")
            problems += cut_problems(name, net, answer["cut"], T, value)
            problems += flow_problems(name, net, s, t, [int(x) for x in answer["flows"]], int(answer["value"]))
        if m <= 600:
            _, residual = REF.edmonds_karp(net, s, t)
            pinned = [str(x) for x in REF.edge_flows(net, residual)]
            covered("Edmonds–Karp flows pinned")
            if mine["edmondsKarp"]["flows"] != pinned:
                problems.append(f"edmondsKarp: flows {mine['edmondsKarp']['flows'][:12]}, the documented procedure {pinned[:12]}")
        if int(mine["value"]) != value:
            problems.append(f"maximumFlowValue {mine['value']}, NetworkX {value}")
        problems += cut_problems("minimumCut(from:to:)", net, mine["cut"], T, value)
        if not directed:
            if int(mine["viewValue"]) != value:
                problems.append(f"directed view: value {mine['viewValue']}, NetworkX {value}")
            if set(mine["viewCut"]["sink"]) != T or mine["viewCut"]["edges"] != mine["cut"]["edges"]:
                problems.append("directed view: its canonical cut differs from the undirected one")
        # Local connectivity.
        adjacent = REF.adjacent(net, s, t)
        if mine["localAdjacent"] != adjacent:
            problems.append(f"minimumVertexCut(from:to:) nil is {mine['localAdjacent']}, adjacent {adjacent}")
        ie = ig_multigraph(net).edge_connectivity(source=s, target=t)
        if mine["localEdge"] != ie:
            problems.append(f"edgeConnectivity(from:to:) {mine['localEdge']}, igraph {ie}")
        kv = nx.node_connectivity(REF.nx_simple(net), s, t)
        if mine["localVertex"] != kv:
            problems.append(f"vertexConnectivity(from:to:) {mine['localVertex']}, NetworkX {kv}")
        if not adjacent:
            cut = mine["localVertexCut"]
            if n <= 80:
                _, model = REF.local_vertex(net, s, t)
                covered("local vertex cuts pinned")
                if cut != model:
                    problems.append(f"minimumVertexCut(from:to:) {cut}, the cut nearest the target {model}")
            if len(cut) != kv:
                problems.append(f"minimumVertexCut(from:to:) has {len(cut)} vertices, κ(s, t) = {kv}")
        # Disjoint paths: as many as λ(s, t) (igraph, parallel edges counted) and κ(s, t), each valid.
        covered("disjoint paths checked")
        if len(mine["edgePaths"]) != ie:
            problems.append(f"edgeDisjointPaths: {len(mine['edgePaths'])} paths, igraph edge_disjoint_paths {ie}")
        if len(mine["vertexPaths"]) != kv:
            problems.append(f"vertexDisjointPaths: {len(mine['vertexPaths'])} paths, NetworkX node_disjoint_paths count {kv}")
        problems += path_problems("edgeDisjointPaths", net, s, t, mine["edgePaths"], False)
        problems += path_problems("vertexDisjointPaths", net, s, t, mine["vertexPaths"], True)
        # Minimum-cost maximum flow.
        mc = mine["minimumCostMaximum"]
        supply = [0] * n
        supply[s], supply[t] = value, -value
        reference = nx_min_cost(arcs, supply)
        if mc["value"] != value or mc["cost"] != reference:
            problems.append(f"minimumCostMaximumFlow: value {mc['value']} cost {mc['cost']}, NetworkX value {value} cost {reference}")
        problems += cost_problems("minimumCostMaximumFlow", arcs, supply, mc["flows"], mc["cost"], mc["potentials"])

    # The global minimum cut.
    g = mine.get("global")
    if n < 2:
        if g is not None:
            problems.append("minimumCut(capacity:) below two vertices is not nil")
    elif g is None:
        problems.append("minimumCut(capacity:) is nil")
    else:
        # The global minimum from igraph maxflow values: every cut separates vertex 0 from some
        # v (either way round in a digraph). igraph's own mincut() crashes (a bus error inside
        # igraph 1.0) on some of these graphs, so it is not called.
        graph, caps = REF.ig_graph(net), [float(c) for c in net.caps()]
        iv = min(min(graph.maxflow_value(0, v, capacity=caps), graph.maxflow_value(v, 0, capacity=caps) if directed else float("inf")) for v in range(1, n))
        if abs(iv - int(g["value"])) > 1e-9:
            problems.append(f"minimumCut(capacity:) value {g['value']}, igraph {iv}")
        # Which minimum cut is not pinned (api.md); its edges and value come from its own sides, and
        # an undirected one has the first vertex on its source side, or, when the positive edges
        # leave several components, exactly the first vertex's component.
        problems += cut_problems("minimumCut(capacity:)", net, g)
        covered("global cuts checked")
        if not directed:
            if 0 in g["sink"]:
                problems.append("minimumCut(capacity:): the first vertex is on the sink side")
            find = REF.components_positive(net, net.caps())
            if any(find(x) != find(0) for x in range(n)):
                covered("global cuts of disconnected graphs pinned")
                T = {x for x in range(n) if find(x) != find(0)}
                if set(g["sink"]) != T:
                    problems.append(f"minimumCut(capacity:) sink side {sorted(g['sink'])[:12]}, the components rule {sorted(T)[:12]}")

    # Gomory–Hu.
    if not directed:
        tree = mine.get("gomoryHu") or []
        if n <= 50:
            reference = {frozenset((u, v)): d["weight"] for u, v, d in nx.gomory_hu_tree(REF.nx_flow_graph(net)).edges(data=True)} if n > 1 else {}
            ours = {frozenset((u, p)): c for u, p, c in tree}
            covered("Gomory–Hu trees compared")
            if ours != reference:
                problems.append(f"gomoryHuTree: {sorted(tuple(sorted(k)) + (c,) for k, c in ours.items())[:8]}, NetworkX {sorted(tuple(sorted(k)) + (c,) for k, c in reference.items())[:8]}")
        if any(child != k + 1 for k, (child, _, _) in enumerate(tree)):
            problems.append("gomoryHuTree: tree edge k does not join vertex k + 1 to its parent")
        graph = REF.ig_graph(net)
        caps = [float(c) for c in net.caps()]
        for (u, v, value, cut_value), sink in zip(mine.get("gomoryHuPairs") or [], mine.get("gomoryHuPairSinks") or []):
            expected = graph.maxflow(u, v, capacity=caps).value
            if value != expected or cut_value != expected:
                problems.append(f"gomoryHuTree: pair {u},{v} value {value} (cut {cut_value}), igraph maxflow {expected}")
            if u in sink or v not in sink:
                problems.append(f"gomoryHuTree: minimumCut(between: {u}, and: {v}) puts them on the wrong sides")
            if REF.cut_value(net, set(range(n)) - set(sink)) != cut_value:
                problems.append(f"gomoryHuTree: minimumCut(between: {u}, and: {v}) value is not its sides' cut")

    # Minimum-cost flow.
    reference = nx_min_cost(arcs, f["supply"])
    covered("minimum-cost feasible", reference is not None)
    covered("minimum-cost infeasible", reference is None)
    if mine["minimumCostFeasible"] != (reference is not None):
        problems.append(f"minimumCostFlow feasible {mine['minimumCostFeasible']}, NetworkX {reference is not None}")
    elif reference is not None:
        answer = mine.get("minimumCost")
        if answer["cost"] != reference:
            problems.append(f"minimumCostFlow cost {answer['cost']}, NetworkX network_simplex {reference}")
        problems += cost_problems("minimumCostFlow", arcs, f["supply"], answer["flows"], answer["cost"], answer["potentials"])
        if answer["value"] != sum(b for b in f["supply"] if b > 0):
            problems.append(f"minimumCostFlow value {answer['value']} is not the positive supplies' sum")

    # Global connectivity.
    lam = ig_multigraph(net).edge_connectivity() if n >= 2 else 0
    if mine["edgeConnectivity"] != lam:
        problems.append(f"edgeConnectivity() {mine['edgeConnectivity']}, igraph {lam}")
    kappa = ig_simple(net).vertex_connectivity() if n >= 2 else 0
    if mine["vertexConnectivity"] != kappa:
        problems.append(f"vertexConnectivity() {mine['vertexConnectivity']}, igraph {kappa}")
    cut = mine["vertexCut"]
    if n <= 30:
        _, model = REF.global_vertex(net)
        covered("global vertex cuts pinned")
        if cut != model:
            problems.append(f"minimumVertexCut() {cut}, Even's pair order {model}")
    if len(cut) != kappa:
        problems.append(f"minimumVertexCut() has {len(cut)} vertices, κ = {kappa}")
    elif n >= 2 and kappa < n - 1 and REF.connected_without(net, set(cut)):
        problems.append(f"minimumVertexCut() {cut[:12]} does not disconnect the graph")
    return problems
