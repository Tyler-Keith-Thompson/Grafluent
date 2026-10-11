"""Reference timings for DirectedAcyclicGraphBenchmarks: the same instances, rebuilt from the same
64-bit LCG (Knuth's MMIX constants), timed in NetworkX and rustworkx.

uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/DirectedAcyclicGraph/timings.py
"""
import time

import networkx as nx
import rustworkx as rx

MASK = (1 << 64) - 1


class LCG:
    def __init__(self, seed):
        self.state = seed

    def next(self):
        self.state = (self.state * 6364136223846793005 + 1442695040888963407) & MASK
        return self.state >> 33


def forward_pairs(n, m, seed):
    """m random pairs over 0..<n, self-pairs skipped, each oriented from the smaller to the larger:
    a DAG whose order is 0, 1, …, n − 1."""
    rng, out = LCG(seed), []
    while len(out) < m:
        a, b = rng.next() % n, rng.next() % n
        if a != b: out.append((min(a, b), max(a, b)))
    return out


def hidden_order_pairs(n, m, seed):
    """Pearce and Kelly's model: a random hidden order (rank), and m random pairs oriented by it."""
    rng = LCG(seed)
    rank = list(range(n))
    for i in range(n - 1, 0, -1):
        j = rng.next() % (i + 1); rank[i], rank[j] = rank[j], rank[i]
    out = []
    while len(out) < m:
        a, b = rng.next() % n, rng.next() % n
        if a == b: continue
        out.append((a, b) if rank[a] < rank[b] else (b, a))
    return out


def random_pairs(n, m, seed):
    """m random pairs over 0..<n, self-pairs skipped, unoriented: most would close a cycle once the
    graph is dense."""
    rng, out = LCG(seed), []
    while len(out) < m:
        a, b = rng.next() % n, rng.next() % n
        if a != b: out.append((a, b))
    return out


def best(f, runs=3):
    times = []
    for _ in range(runs):
        t = time.perf_counter(); f(); times.append(time.perf_counter() - t)
    return min(times) * 1000


def main():
    small = nx.DiGraph(); small.add_nodes_from(range(1000)); small.add_edges_from(forward_pairs(1000, 3000, 11))
    print(f"closure instance: n=1000, m={small.number_of_edges()}, closure edges {nx.transitive_closure_dag(small).number_of_edges()}")
    print(f"networkx transitive_closure_dag: {best(lambda: nx.transitive_closure_dag(small)):.1f} ms")
    print(f"networkx transitive_reduction: {best(lambda: nx.transitive_reduction(small)):.1f} ms")
    big = nx.DiGraph(); big.add_nodes_from(range(100_000)); big.add_edges_from(forward_pairs(100_000, 500_000, 12))
    print(f"longest-path instance: n=100000, m={big.number_of_edges()}, length {nx.dag_longest_path_length(big)}")
    print(f"networkx dag_longest_path: {best(lambda: nx.dag_longest_path(big)):.1f} ms")
    for n, m in ((10_000, 50_000), (100_000, 200_000)):
        pairs = hidden_order_pairs(n, m, 13)

        def insert():
            g = rx.PyDiGraph(check_cycle=True)
            g.add_nodes_from(range(n))
            for a, b in pairs: g.add_edge(a, b, None)
        print(f"rustworkx PyDiGraph(check_cycle=True) add_edge, hidden-order model n={n} m={m}: {best(insert, 1):.0f} ms")

    pairs = random_pairs(10_000, 100_000, 14)

    def insert_random():
        g = rx.PyDiGraph(check_cycle=True)
        g.add_nodes_from(range(10_000))
        rejected = 0
        for a, b in pairs:
            try: g.add_edge(a, b, None)
            except rx.DAGWouldCycle: rejected += 1
        return rejected
    print(f"rustworkx PyDiGraph(check_cycle=True) add_edge, 10^5 random pairs over 10^4 vertices: {best(insert_random, 1):.0f} ms, {insert_random()} rejected")


if __name__ == "__main__":
    main()
