// Boost Graph Library harness: `cross-bgl <algorithm> <instance> <repeats>`.
// Directed traversals and shortest paths run on both adjacency_list<vecS, vecS> and
// compressed_sparse_row_graph; everything else on adjacency_list<vecS, vecS>.
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/betweenness_centrality.hpp>
#include <boost/graph/bellman_ford_shortest_paths.hpp>
#include <boost/graph/biconnected_components.hpp>
#include <boost/graph/breadth_first_search.hpp>
#include <boost/graph/clustering_coefficient.hpp>
#include <boost/graph/compressed_sparse_row_graph.hpp>
#include <boost/graph/connected_components.hpp>
#include <boost/graph/depth_first_search.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>
#include <boost/graph/floyd_warshall_shortest.hpp>
#include <boost/graph/kruskal_min_spanning_tree.hpp>
#include <boost/graph/max_cardinality_matching.hpp>
#include <boost/graph/prim_minimum_spanning_tree.hpp>
#include <boost/graph/push_relabel_max_flow.hpp>
#include <boost/graph/strong_components.hpp>
#include <boost/graph/topological_sort.hpp>
#include <boost/graph/vf2_sub_graph_iso.hpp>
#include <cstring>
#include <limits>

#include "common.hpp"

using namespace boost;
typedef long long W;
typedef adjacency_list<vecS, vecS, directedS, no_property, property<edge_weight_t, W>> DirG;
typedef adjacency_list<vecS, vecS, undirectedS, no_property, property<edge_weight_t, W>> UndG;
struct EdgeW { W w; };
typedef compressed_sparse_row_graph<directedS, no_property, EdgeW> CsrG;

static std::vector<std::pair<long, long>> pairs(const Instance& g, bool second = false) {
  std::vector<std::pair<long, long>> e(g.m);
  for (long k = 0; k < g.m; ++k) e[k] = second ? std::make_pair(g.u2[k], g.v2[k]) : std::make_pair(g.u[k], g.v[k]);
  return e;
}
static DirG make_dir(const Instance& g) { auto e = pairs(g); return DirG(e.begin(), e.end(), g.w.begin(), g.n); }
static UndG make_und(const Instance& g, bool second = false) { auto e = pairs(g, second); return UndG(e.begin(), e.end(), g.w.begin(), g.n); }
static CsrG make_csr(const Instance& g) {
  auto e = pairs(g);
  std::vector<EdgeW> props(g.m);
  for (long k = 0; k < g.m; ++k) props[k].w = g.w[k];
  return CsrG(edges_are_unsorted_multi_pass, e.begin(), e.end(), props.begin(), g.n);
}

struct DiscoverCounter : default_bfs_visitor {
  long* count;
  explicit DiscoverCounter(long* c) : count(c) {}
  template <class V, class G> void discover_vertex(V, const G&) const { ++*count; }
};
struct DfsDiscoverCounter : default_dfs_visitor {
  long* count;
  explicit DfsDiscoverCounter(long* c) : count(c) {}
  template <class V, class G> void discover_vertex(V, const G&) const { ++*count; }
};

template <class G, class WeightMap> void directed_case(const std::string& alg, const Instance& g, const G& gr, WeightMap wm, int k, const char* rep) {
  std::vector<double> t;
  long n = g.n;
  if (alg == "bfs") {
    long c = measure(k, [&] {
      long count = 0;
      std::vector<default_color_type> color(n);
      breadth_first_search(gr, vertex(0, gr), visitor(DiscoverCounter(&count)).color_map(make_iterator_property_map(color.begin(), get(vertex_index, gr))));
      return count;
    }, t);
    report(rep, std::to_string(c), t);
  } else if (alg == "dfs") {
    long c = measure(k, [&] {
      long count = 0;
      std::vector<default_color_type> color(n, white_color);
      depth_first_visit(gr, vertex(0, gr), DfsDiscoverCounter(&count), make_iterator_property_map(color.begin(), get(vertex_index, gr)));
      return count;
    }, t);
    report(rep, std::to_string(c), t);
  } else if (alg == "scc") {
    long c = measure(k, [&] {
      std::vector<long> comp(n);
      return (long)strong_components(gr, make_iterator_property_map(comp.begin(), get(vertex_index, gr)));
    }, t);
    report(rep, std::to_string(c), t);
  } else if (alg == "dijkstra" || alg == "bellman-ford") {
    std::vector<W> dist;
    if (alg == "dijkstra") {
      dist = measure(k, [&] {
        std::vector<W> d(n);
        std::vector<typename graph_traits<G>::vertex_descriptor> pred(n);
        dijkstra_shortest_paths(gr, vertex(0, gr), weight_map(wm)
            .distance_map(make_iterator_property_map(d.begin(), get(vertex_index, gr)))
            .predecessor_map(make_iterator_property_map(pred.begin(), get(vertex_index, gr))));
        return d;
      }, t);
    } else {
      dist = measure(k, [&] {
        std::vector<W> d(n, std::numeric_limits<W>::max());
        std::vector<typename graph_traits<G>::vertex_descriptor> pred(n);
        for (long i = 0; i < n; ++i) pred[i] = i;
        d[0] = 0;
        bellman_ford_shortest_paths(gr, (int)n, weight_map(wm)
            .distance_map(make_iterator_property_map(d.begin(), get(vertex_index, gr)))
            .predecessor_map(make_iterator_property_map(pred.begin(), get(vertex_index, gr))));
        return d;
      }, t);
    }
    long reached = 0; W sum = 0;
    for (W d : dist) if (d != std::numeric_limits<W>::max()) { ++reached; sum += d; }
    report(rep, std::to_string(reached) + "," + std::to_string(sum), t);
  } else if (alg == "topo") {
    auto order = measure(k, [&] {
      std::vector<typename graph_traits<G>::vertex_descriptor> out;
      out.reserve(n);
      topological_sort(gr, std::back_inserter(out));
      return out;
    }, t);
    std::vector<long> o(order.rbegin(), order.rend());
    report(rep, topo_check(g, o), t);
  }
}

int main(int argc, char** argv) {
  if (argc != 4) { std::fprintf(stderr, "usage: cross-bgl <algorithm> <instance> <repeats>\n"); return 2; }
  std::string alg = argv[1];
  Instance g = load(argv[2]);
  int k = std::atoi(argv[3]);
  std::vector<double> t;

  if (alg == "build-directed") {
    DirG a = measure(k, [&] { return make_dir(g); }, t);
    report("adjacency_list", std::to_string(num_vertices(a)) + "," + std::to_string(num_edges(a)), t);
    t.clear();
    CsrG b = measure(k, [&] { return make_csr(g); }, t);
    report("compressed_sparse_row_graph", std::to_string(num_vertices(b)) + "," + std::to_string(num_edges(b)), t);
  } else if (alg == "build-undirected") {
    UndG a = measure(k, [&] { return make_und(g); }, t);
    report("adjacency_list", std::to_string(num_vertices(a)) + "," + std::to_string(num_edges(a)), t);
  } else if (alg == "insert") {
    DirG a = measure(k, [&] {
      DirG d(g.n);
      for (long e = 0; e < g.m; ++e) add_edge(g.u[e], g.v[e], g.w[e], d);
      return d;
    }, t);
    report("adjacency_list", std::to_string(num_vertices(a)) + "," + std::to_string(num_edges(a)), t);
  } else if (alg == "insert-walk") {
    DirG d(g.n);
    for (long e = 0; e < g.m; ++e) add_edge(g.u[e], g.v[e], g.w[e], d);
    auto r = measure(k, [&] {
      long count = 0; long long sum = 0;
      for (long v = 0; v < g.n; ++v)
        for (auto it = out_edges(v, d); it.first != it.second; ++it.first) { sum += (long long)v * g.n + (long long)target(*it.first, d); ++count; }
      return std::make_pair(count, sum);
    }, t);
    report("adjacency_list", walk_check(r.first, r.second), t);
  } else if (alg == "remove") {
    // Each repeat removes from a fresh copy; the copy is made outside the timed region.
    DirG built(g.n);
    for (long e = 0; e < g.m; ++e) add_edge(g.u[e], g.v[e], g.w[e], built);
    long count = 0; long long sum = 0;
    for (int r = 0; r < k; ++r) {
      DirG d = built;
      auto t0 = std::chrono::steady_clock::now();
      for (long e = 0; e < g.m / 2; ++e) remove_edge(g.u[e], g.v[e], d);
      auto t1 = std::chrono::steady_clock::now();
      t.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
      count = 0; sum = 0;
      for (long v = 0; v < g.n; ++v)
        for (auto it = out_edges(v, d); it.first != it.second; ++it.first) { sum += (long long)v * g.n + (long long)target(*it.first, d); ++count; }
    }
    report("adjacency_list", walk_check(count, sum), t);
  } else if (alg == "bfs" || alg == "dfs" || alg == "scc" || alg == "dijkstra" || alg == "bellman-ford" || alg == "topo") {
    DirG a = make_dir(g);
    directed_case(alg, g, a, get(edge_weight, a), k, "adjacency_list");
    CsrG b = make_csr(g);
    directed_case(alg, g, b, get(&EdgeW::w, b), k, "compressed_sparse_row_graph");
  } else if (alg == "cc") {
    UndG a = make_und(g);
    long c = measure(k, [&] { std::vector<long> comp(g.n); return (long)connected_components(a, &comp[0]); }, t);
    report("adjacency_list", std::to_string(c), t);
  } else if (alg == "mst-kruskal") {
    UndG a = make_und(g);
    auto edges = measure(k, [&] {
      std::vector<graph_traits<UndG>::edge_descriptor> out;
      kruskal_minimum_spanning_tree(a, std::back_inserter(out));
      return out;
    }, t);
    W sum = 0;
    for (auto e : edges) sum += get(edge_weight, a, e);
    report("adjacency_list", std::to_string(edges.size()) + "," + std::to_string(sum), t);
  } else if (alg == "mst-prim") {
    UndG a = make_und(g);
    auto pd = measure(k, [&] {
      std::vector<graph_traits<UndG>::vertex_descriptor> pred(g.n);
      std::vector<W> d(g.n);
      prim_minimum_spanning_tree(a, &pred[0], distance_map(&d[0]));
      return std::make_pair(pred, d);
    }, t);
    long count = 0; W sum = 0;
    for (long v = 0; v < g.n; ++v) if ((long)pd.first[v] != v) { ++count; sum += pd.second[v]; }
    report("adjacency_list (spans the root's component)", std::to_string(count) + "," + std::to_string(sum), t);
  } else if (alg == "maxflow-pr") {
    typedef adjacency_list_traits<vecS, vecS, directedS> Traits;
    typedef adjacency_list<vecS, vecS, directedS, no_property,
        property<edge_capacity_t, W, property<edge_residual_capacity_t, W, property<edge_reverse_t, Traits::edge_descriptor>>>> FlowG;
    FlowG fg(g.n);
    auto cap = get(edge_capacity, fg);
    auto rev = get(edge_reverse, fg);
    for (long e = 0; e < g.m; ++e) {
      auto a = add_edge(g.u[e], g.v[e], fg).first, b = add_edge(g.v[e], g.u[e], fg).first;
      cap[a] = g.w[e]; cap[b] = 0; rev[a] = b; rev[b] = a;
    }
    W value = measure(k, [&] { return push_relabel_max_flow(fg, g.s, g.t); }, t);
    report("adjacency_list with reverse arcs", std::to_string(value), t);
  } else if (alg == "matching" || alg == "bip-matching") {
    UndG a = make_und(g);
    long size = measure(k, [&] {
      std::vector<graph_traits<UndG>::vertex_descriptor> mate(g.n);
      matching<UndG, graph_traits<UndG>::vertex_descriptor*, property_map<UndG, vertex_index_t>::type,
          edmonds_augmenting_path_finder, extra_greedy_matching, no_matching_verifier>(a, &mate[0], get(vertex_index, a));
      return (long)matching_size(a, &mate[0]);
    }, t);
    report(alg == "matching" ? "adjacency_list" : "adjacency_list (general algorithm)", std::to_string(size), t);
  } else if (alg == "iso") {
    UndG a = make_und(g), b = make_und(g, true);
    bool iso = measure(k, [&] {
      auto stop = [](auto&&, auto&&) { return false; };
      return vf2_graph_iso(a, b, stop);
    }, t);
    report("adjacency_list (VF2)", iso ? "1" : "0", t);
  } else if (alg == "bc") {
    UndG a = make_und(g);
    auto c = measure(k, [&] {
      std::vector<double> centrality(g.n);
      brandes_betweenness_centrality(a, centrality_map(make_iterator_property_map(centrality.begin(), get(vertex_index, a))));
      return centrality;
    }, t);
    double sum = 0;
    for (double x : c) sum += x;
    report("adjacency_list", fmt_float(sum), t);
  } else if (alg == "triangles") {
    UndG a = make_und(g);
    long c = measure(k, [&] {
      long total = 0;
      for (long v = 0; v < g.n; ++v) total += (long)num_triangles_on_vertex(a, v);
      return total / 3;
    }, t);
    report("adjacency_list (num_triangles_on_vertex)", std::to_string(c), t);
  } else if (alg == "articulation") {
    UndG a = make_und(g);
    long c = measure(k, [&] {
      std::vector<graph_traits<UndG>::vertex_descriptor> out;
      articulation_points(a, std::back_inserter(out));
      return (long)out.size();
    }, t);
    report("adjacency_list", std::to_string(c), t);
  } else if (alg == "fw") {
    typedef adjacency_list<vecS, vecS, directedS, no_property, property<edge_weight_t, double>> FwG;
    auto e = pairs(g);
    std::vector<double> wd(g.w.begin(), g.w.end());
    FwG a(e.begin(), e.end(), wd.begin(), g.n);
    auto d = measure(k, [&] {
      std::vector<std::vector<double>> D(g.n, std::vector<double>(g.n));
      floyd_warshall_all_pairs_shortest_paths(a, D);
      return D;
    }, t);
    long finite = 0; double sum = 0;
    for (auto& row : d) for (double x : row) if (x < std::numeric_limits<double>::max()) { ++finite; sum += x; }
    char b[64];
    std::snprintf(b, sizeof b, "%ld,%.0f", finite, sum);
    report("adjacency_list (double weights)", b, t);
  } else if (alg == "pagerank") {
    std::printf("NA page_rank has no dangling-vertex redistribution and a fixed iteration count: a different answer\n");
  } else if (alg == "maxflow-value") {
    std::printf("NA push_relabel_max_flow always completes the flow\n");
  } else if (alg == "bridges") {
    std::printf("NA no bridges function\n");
  } else {
    std::printf("NA not in BGL\n");
  }
  return 0;
}
