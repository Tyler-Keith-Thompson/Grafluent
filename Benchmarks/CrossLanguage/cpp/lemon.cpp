// LEMON harness: `cross-lemon <algorithm> <instance> <repeats>`, on SmartDigraph / SmartGraph
// (LEMON's fastest growable graphs; arcs and nodes stored in arrays).
#include <lemon/bellman_ford.h>
#include <lemon/bfs.h>
#include <lemon/connectivity.h>
#include <lemon/dfs.h>
#include <lemon/dijkstra.h>
#include <lemon/kruskal.h>
#include <lemon/matching.h>
#include <lemon/preflow.h>
#include <lemon/smart_graph.h>

#include "common.hpp"

using namespace lemon;
typedef long long W;

static void build_dir(const Instance& g, SmartDigraph& d, SmartDigraph::ArcMap<W>* w) {
  d.reserveNode(g.n);
  d.reserveArc(g.m);
  for (long i = 0; i < g.n; ++i) d.addNode();
  for (long k = 0; k < g.m; ++k) {
    auto a = d.addArc(d.nodeFromId(g.u[k]), d.nodeFromId(g.v[k]));
    if (w) (*w)[a] = g.w[k];
  }
}
static void build_und(const Instance& g, SmartGraph& d, SmartGraph::EdgeMap<W>* w, bool second = false) {
  d.reserveNode(g.n);
  d.reserveEdge(g.m);
  for (long i = 0; i < g.n; ++i) d.addNode();
  const auto& us = second ? g.u2 : g.u;
  const auto& vs = second ? g.v2 : g.v;
  for (long k = 0; k < g.m; ++k) {
    auto e = d.addEdge(d.nodeFromId(us[k]), d.nodeFromId(vs[k]));
    if (w) (*w)[e] = g.w[k];
  }
}

int main(int argc, char** argv) {
  if (argc != 4) { std::fprintf(stderr, "usage: cross-lemon <algorithm> <instance> <repeats>\n"); return 2; }
  std::string alg = argv[1];
  Instance g = load(argv[2]);
  int k = std::atoi(argv[3]);
  std::vector<double> t;

  if (alg == "build-directed") {
    long arcs = measure(k, [&] { SmartDigraph d; SmartDigraph::ArcMap<W> w(d); build_dir(g, d, &w); return (long)countArcs(d); }, t);
    report("SmartDigraph", std::to_string(g.n) + "," + std::to_string(arcs), t);
  } else if (alg == "build-undirected") {
    long edges = measure(k, [&] { SmartGraph d; SmartGraph::EdgeMap<W> w(d); build_und(g, d, &w); return (long)countEdges(d); }, t);
    report("SmartGraph", std::to_string(g.n) + "," + std::to_string(edges), t);
  } else if (alg == "bfs" || alg == "dfs") {
    SmartDigraph d;
    build_dir(g, d, nullptr);
    auto s = d.nodeFromId(0);
    long c;
    if (alg == "bfs") {
      c = measure(k, [&] {
        Bfs<SmartDigraph> bfs(d);
        bfs.run(s);
        long count = 0;
        for (SmartDigraph::NodeIt v(d); v != INVALID; ++v) count += bfs.reached(v);
        return count;
      }, t);
    } else {
      c = measure(k, [&] {
        Dfs<SmartDigraph> dfs(d);
        dfs.run(s);
        long count = 0;
        for (SmartDigraph::NodeIt v(d); v != INVALID; ++v) count += dfs.reached(v);
        return count;
      }, t);
    }
    report("SmartDigraph (run, then count reached)", std::to_string(c), t);
  } else if (alg == "scc") {
    SmartDigraph d;
    build_dir(g, d, nullptr);
    long c = measure(k, [&] { SmartDigraph::NodeMap<int> comp(d); return (long)stronglyConnectedComponents(d, comp); }, t);
    report("SmartDigraph", std::to_string(c), t);
  } else if (alg == "cc") {
    SmartGraph d;
    build_und(g, d, nullptr);
    long c = measure(k, [&] { SmartGraph::NodeMap<int> comp(d); return (long)connectedComponents(d, comp); }, t);
    report("SmartGraph", std::to_string(c), t);
  } else if (alg == "dijkstra" || alg == "bellman-ford") {
    SmartDigraph d;
    SmartDigraph::ArcMap<W> w(d);
    build_dir(g, d, &w);
    auto s = d.nodeFromId(0);
    long reached = 0; W sum = 0;
    if (alg == "dijkstra") {
      auto pr = measure(k, [&] {
        Dijkstra<SmartDigraph, SmartDigraph::ArcMap<W>> dj(d, w);
        dj.run(s);
        long r = 0; W total = 0;
        for (SmartDigraph::NodeIt v(d); v != INVALID; ++v) if (dj.reached(v)) { ++r; total += dj.dist(v); }
        return std::make_pair(r, total);
      }, t);
      reached = pr.first; sum = pr.second;
    } else {
      auto pr = measure(k, [&] {
        BellmanFord<SmartDigraph, SmartDigraph::ArcMap<W>> bf(d, w);
        bf.run(s);
        long r = 0; W total = 0;
        for (SmartDigraph::NodeIt v(d); v != INVALID; ++v) if (bf.reached(v)) { ++r; total += bf.dist(v); }
        return std::make_pair(r, total);
      }, t);
      reached = pr.first; sum = pr.second;
    }
    report("SmartDigraph", std::to_string(reached) + "," + std::to_string(sum), t);
  } else if (alg == "mst-kruskal") {
    SmartGraph d;
    SmartGraph::EdgeMap<W> w(d);
    build_und(g, d, &w);
    auto pr = measure(k, [&] {
      std::vector<SmartGraph::Edge> tree;
      W cost = kruskal(d, w, std::back_inserter(tree));
      return std::make_pair((long)tree.size(), cost);
    }, t);
    report("SmartGraph", std::to_string(pr.first) + "," + std::to_string(pr.second), t);
  } else if (alg == "topo") {
    SmartDigraph d;
    build_dir(g, d, nullptr);
    auto order = measure(k, [&] {
      SmartDigraph::NodeMap<int> pos(d);
      topologicalSort(d, pos);
      std::vector<long> out(g.n);
      for (SmartDigraph::NodeIt v(d); v != INVALID; ++v) out[pos[v]] = d.id(v);
      return out;
    }, t);
    report("SmartDigraph", topo_check(g, order), t);
  } else if (alg == "maxflow-pr" || alg == "maxflow-value") {
    SmartDigraph d;
    SmartDigraph::ArcMap<W> cap(d);
    build_dir(g, d, &cap);
    auto s = d.nodeFromId(g.s), tt = d.nodeFromId(g.t);
    bool full = alg == "maxflow-pr";
    W value = measure(k, [&] {
      Preflow<SmartDigraph, SmartDigraph::ArcMap<W>> p(d, cap, s, tt);
      if (full) p.run(); else p.runMinCut();
      return p.flowValue();
    }, t);
    report(full ? "SmartDigraph (Preflow::run)" : "SmartDigraph (Preflow::runMinCut)", std::to_string(value), t);
  } else if (alg == "matching" || alg == "bip-matching") {
    SmartGraph d;
    build_und(g, d, nullptr);
    long size = measure(k, [&] { MaxMatching<SmartGraph> mm(d); mm.run(); return (long)mm.matchingSize(); }, t);
    report(alg == "matching" ? "SmartGraph" : "SmartGraph (general algorithm)", std::to_string(size), t);
  } else if (alg == "articulation") {
    SmartGraph d;
    build_und(g, d, nullptr);
    long c = measure(k, [&] { SmartGraph::NodeMap<bool> cut(d, false); return (long)biNodeConnectedCutNodes(d, cut); }, t);
    report("SmartGraph", std::to_string(c), t);
  } else if (alg == "bridges") {
    SmartGraph d;
    build_und(g, d, nullptr);
    long c = measure(k, [&] { SmartGraph::EdgeMap<bool> cut(d, false); return (long)biEdgeConnectedCutEdges(d, cut); }, t);
    report("SmartGraph", std::to_string(c), t);
  } else if (alg == "mst-prim") {
    std::printf("NA no Prim (kruskal only)\n");
  } else if (alg == "maxflow-dinic") {
    std::printf("NA no Dinic (Preflow, EdmondsKarp)\n");
  } else {
    std::printf("NA not in LEMON 1.3.1\n");
  }
  return 0;
}
