// Packed CSR harness (Wheatman and Xu's single-threaded PCSR): `cross-pcsr <algorithm> <instance>
// <repeats>`. The dynamic rows only: inserting arcs one at a time into a graph of n vertices, and
// walking every row afterwards, read straight from the packed edge array as PCSR's own
// `get_edges` does. PCSR has no edge removal, so the remove row is n/a. Vertices are 0..<n; the
// arc's weight is its value, which PCSR requires to be nonzero.
#include <cstring>
#include <string>

#include "PCSR.hpp"
#include "common.hpp"

static PCSR* inserted(const Instance& g) {
  PCSR* p = new PCSR((uint32_t)g.n);
  for (long k = 0; k < g.m; ++k) p->add_edge((uint32_t)g.u[k], (uint32_t)g.v[k], (uint32_t)g.w[k]);
  return p;
}

static std::pair<long, long long> walk(const PCSR& p, long n) {
  long count = 0;
  long long sum = 0;
  for (long v = 0; v < n; ++v) {
    uint32_t start = p.nodes[v].beginning, end = p.nodes[v].end;
    for (uint32_t j = start + 1; j < end; ++j) {
      edge_t e = p.edges.items[j];
      if (e.value != 0) { sum += (long long)v * n + e.dest; ++count; }
    }
  }
  return {count, sum};
}

int main(int argc, char** argv) {
  if (argc != 4) { std::fprintf(stderr, "usage: cross-pcsr <algorithm> <instance> <repeats>\n"); return 2; }
  std::string alg = argv[1];
  Instance g = load(argv[2]);
  int k = std::atoi(argv[3]);
  std::vector<double> t;
  if (alg == "insert") {
    PCSR* p = measure(k, [&] { return inserted(g); }, t);
    long count = 0;
    for (long v = 0; v < g.n; ++v) count += p->nodes[v].num_neighbors;
    report("PCSR", std::to_string(p->get_n()) + "," + std::to_string(count), t);
  } else if (alg == "insert-walk") {
    PCSR* p = inserted(g);
    auto r = measure(k, [&] { return walk(*p, g.n); }, t);
    report("PCSR", walk_check(r.first, r.second), t);
  } else if (alg == "remove") {
    std::printf("NA PCSR has no edge removal (add_edge and add_edge_update only)\n");
  } else {
    std::printf("NA not in PCSR (a representation; the dynamic rows only)\n");
  }
  return 0;
}
