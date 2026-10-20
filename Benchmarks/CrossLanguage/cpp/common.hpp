// Shared by the C++ harnesses: instance loading, timing and the output protocol
// (`RESULT <representation> <check> <ms,ms,…>` or `NA <reason>`).
#pragma once
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

struct Instance {
  long n = 0, m = 0, s = 0, t = 0, nleft = 0, blocks = 1;
  std::vector<long> u, v, u2, v2;
  std::vector<long long> w;
};

inline Instance load(const char* path) {
  FILE* f = std::fopen(path, "rb");
  if (!f) { std::perror(path); std::exit(1); }
  std::fseek(f, 0, SEEK_END);
  long size = std::ftell(f);
  std::fseek(f, 0, SEEK_SET);
  std::vector<char> buf(size + 1);
  if (std::fread(buf.data(), 1, size, f) != (size_t)size) { std::perror(path); std::exit(1); }
  std::fclose(f);
  buf[size] = 0;
  const char* p = buf.data();
  auto next = [&]() -> long long {
    while (*p < '0' || *p > '9') ++p;
    long long x = 0;
    while (*p >= '0' && *p <= '9') x = x * 10 + (*p++ - '0');
    return x;
  };
  Instance g;
  g.n = next(); g.m = next(); g.s = next(); g.t = next(); g.nleft = next(); g.blocks = next();
  g.u.resize(g.m); g.v.resize(g.m); g.w.resize(g.m);
  for (long k = 0; k < g.m; ++k) { g.u[k] = next(); g.v[k] = next(); g.w[k] = next(); }
  if (g.blocks > 1) {
    g.u2.resize(g.m); g.v2.resize(g.m);
    for (long k = 0; k < g.m; ++k) { g.u2[k] = next(); g.v2[k] = next(); next(); }
  }
  return g;
}

template <class T> inline void keep(T const& value) { asm volatile("" : : "r"(&value) : "memory"); }

template <class F> auto measure(int repeats, F&& body, std::vector<double>& times) {
  using R = decltype(body());
  R last{};
  for (int r = 0; r < repeats; ++r) {
    auto t0 = std::chrono::steady_clock::now();
    R result = body();
    auto t1 = std::chrono::steady_clock::now();
    keep(result);
    times.push_back(std::chrono::duration<double, std::milli>(t1 - t0).count());
    last = std::move(result);
  }
  return last;
}

inline void report(const std::string& rep, const std::string& check, const std::vector<double>& times) {
  std::printf("RESULT %s %s ", rep.c_str(), check.c_str());
  for (size_t i = 0; i < times.size(); ++i) std::printf(i ? ",%.4f" : "%.4f", times[i]);
  std::printf("\n");
}

inline std::string fmt_float(double x) {
  char b[64];
  std::snprintf(b, sizeof b, "%.12e", x);
  return b;
}

inline std::string topo_check(const Instance& g, const std::vector<long>& order) {
  std::vector<long> pos(g.n, -1);
  for (size_t k = 0; k < order.size(); ++k) pos[order[k]] = (long)k;
  if ((long)order.size() != g.n) return "invalid";
  for (long k = 0; k < g.m; ++k)
    if (pos[g.u[k]] >= pos[g.v[k]]) return "invalid";
  return "valid," + std::to_string(order.size());
}

// The check of a walk over every row: the arcs seen and Σ (u·n + v) over them, which does not
// depend on the order the rows are read in.
inline std::string walk_check(long count, long long sum) { return std::to_string(count) + "," + std::to_string(sum); }
