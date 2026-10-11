// Boost.Graph baseline for Planarity (api.md, Performance): boyer_myrvold_planarity_test, alone
// and with the embedding and Kuratowski subgraph outputs, best of 5, on instance files written by
// `PL_DUMP=<dir> ref.py --bench` (first line "n m", then one "u v" per edge).
// Build: clang++ -O2 -std=c++17 -I/opt/homebrew/include boost_bench.cpp -o boost_bench
// Not compiled by the package (the catalog folder is in .bazelignore).
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/boyer_myrvold_planar_test.hpp>
#include <boost/graph/planar_face_traversal.hpp>
#include <chrono>
#include <fstream>
#include <iostream>
#include <vector>
using namespace boost;
typedef adjacency_list<vecS, vecS, undirectedS, property<vertex_index_t, int>, property<edge_index_t, int>> G;
int main(int argc, char** argv) {
  for (int a = 1; a < argc; a++) {
    std::ifstream in(argv[a]); int n, m; in >> n >> m; G g(n);
    for (int i = 0; i < m; i++) { int u, v; in >> u >> v; add_edge(u, v, g); }
    graph_traits<G>::edges_size_type c = 0; graph_traits<G>::edge_iterator ei, ee;
    for (tie(ei, ee) = edges(g); ei != ee; ++ei) put(edge_index, g, *ei, c++);
    double best1 = 1e18, best2 = 1e18; bool planar = false;
    for (int r = 0; r < 5; r++) {
      auto t0 = std::chrono::steady_clock::now();
      planar = boyer_myrvold_planarity_test(g);
      auto t1 = std::chrono::steady_clock::now();
      best1 = std::min(best1, std::chrono::duration<double, std::milli>(t1 - t0).count());
      typedef std::vector<std::vector<graph_traits<G>::edge_descriptor>> E;
      E emb(num_vertices(g)); std::vector<graph_traits<G>::edge_descriptor> kur;
      t0 = std::chrono::steady_clock::now();
      boyer_myrvold_planarity_test(boyer_myrvold_params::graph = g,
          boyer_myrvold_params::embedding = make_iterator_property_map(emb.begin(), get(vertex_index, g)),
          boyer_myrvold_params::kuratowski_subgraph = std::back_inserter(kur));
      t1 = std::chrono::steady_clock::now();
      best2 = std::min(best2, std::chrono::duration<double, std::milli>(t1 - t0).count());
      if (r == 0 && !planar) std::cerr << argv[a] << " kuratowski edges " << kur.size() << "\n";
    }
    std::cout << argv[a] << " n=" << n << " m=" << m << " planar=" << planar << " test " << best1 << " ms, with witness " << best2 << " ms\n";
  }
}
