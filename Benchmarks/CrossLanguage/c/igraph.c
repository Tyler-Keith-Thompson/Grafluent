/* igraph C core harness: `cross-igraph <algorithm> <instance> <repeats>`, on igraph_t (igraph's
 * indexed edge list). Same output protocol as the other harnesses. */
#include <igraph.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    long n, m, s, t, nleft, blocks;
    long *u, *v, *u2, *v2;
    long long *w;
} Instance;

static Instance load(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); exit(1); }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc(size + 1);
    if (fread(buf, 1, size, f) != (size_t)size) { perror(path); exit(1); }
    fclose(f);
    buf[size] = 0;
    const char *p = buf;
#define NEXT() ({ while (*p < '0' || *p > '9') ++p; long long x_ = 0; while (*p >= '0' && *p <= '9') x_ = x_ * 10 + (*p++ - '0'); x_; })
    Instance g;
    g.n = NEXT(); g.m = NEXT(); g.s = NEXT(); g.t = NEXT(); g.nleft = NEXT(); g.blocks = NEXT();
    g.u = malloc(sizeof(long) * g.m); g.v = malloc(sizeof(long) * g.m); g.w = malloc(sizeof(long long) * g.m);
    g.u2 = g.v2 = NULL;
    for (long k = 0; k < g.m; ++k) { g.u[k] = NEXT(); g.v[k] = NEXT(); g.w[k] = NEXT(); }
    if (g.blocks > 1) {
        g.u2 = malloc(sizeof(long) * g.m); g.v2 = malloc(sizeof(long) * g.m);
        for (long k = 0; k < g.m; ++k) { g.u2[k] = NEXT(); g.v2[k] = NEXT(); (void)NEXT(); }
    }
#undef NEXT
    free(buf);
    return g;
}

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1e3 + ts.tv_nsec / 1e6;
}

static double times[1024];
static int ntimes;

static void report(const char *rep, const char *check) {
    printf("RESULT %s %s ", rep, check);
    for (int i = 0; i < ntimes; ++i) printf(i ? ",%.4f" : "%.4f", times[i]);
    printf("\n");
    ntimes = 0;
}

/* igraph caches graph properties (connectedness, acyclicity, …) in the igraph_t, so a repeated
 * run could answer from the cache. Every graph `make` builds is listed here and its cache cleared
 * before each timed run. */
static const igraph_t *built[2];
static int nbuilt;

static void invalidate_all(void) {
    for (int i = 0; i < nbuilt; ++i) igraph_invalidate_cache(built[i]);
}

/* Times `body` `k` times; `body` must leave its answer in variables declared before the loop. */
#define MEASURE(k, body) do { for (int r_ = 0; r_ < (k); ++r_) { invalidate_all(); double t0_ = now_ms(); body; times[ntimes++] = now_ms() - t0_; } } while (0)

static void edge_vector(const Instance *g, int second, igraph_vector_int_t *e) {
    igraph_vector_int_init(e, 2 * g->m);
    for (long k = 0; k < g->m; ++k) {
        VECTOR(*e)[2 * k] = second ? g->u2[k] : g->u[k];
        VECTOR(*e)[2 * k + 1] = second ? g->v2[k] : g->v[k];
    }
}

static void make(const Instance *g, int directed, int second, igraph_t *out) {
    igraph_vector_int_t e;
    edge_vector(g, second, &e);
    igraph_create(out, &e, g->n, directed);
    igraph_vector_int_destroy(&e);
    built[nbuilt++] = out;
}

static void weights(const Instance *g, igraph_vector_t *w) {
    igraph_vector_init(w, g->m);
    for (long k = 0; k < g->m; ++k) VECTOR(*w)[k] = (double)g->w[k];
}

int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "usage: cross-igraph <algorithm> <instance> <repeats>\n"); return 2; }
    const char *alg = argv[1];
    Instance g = load(argv[2]);
    int k = atoi(argv[3]);
    char check[128];
#define IS(x) (strcmp(alg, x) == 0)

    if (IS("build-directed") || IS("build-undirected")) {
        igraph_vector_int_t e;
        edge_vector(&g, 0, &e);
        igraph_integer_t nv = 0, ne = 0;
        int directed = IS("build-directed");
        MEASURE(k, { igraph_t gr; igraph_create(&gr, &e, g.n, directed); nv = igraph_vcount(&gr); ne = igraph_ecount(&gr); igraph_destroy(&gr); });
        snprintf(check, sizeof check, "%ld,%ld", (long)nv, (long)ne);
        report("igraph_t (igraph_create, includes destroy)", check);
    } else if (IS("bfs") || IS("dfs")) {
        igraph_t gr; make(&g, 1, 0, &gr);
        long reached = 0;
        if (IS("bfs")) {
            MEASURE(k, { igraph_vector_int_t order; igraph_vector_int_init(&order, 0);
                igraph_bfs_simple(&gr, 0, IGRAPH_OUT, &order, NULL, NULL);
                reached = igraph_vector_int_size(&order); igraph_vector_int_destroy(&order); });
            report("igraph_t (igraph_bfs_simple)", (snprintf(check, sizeof check, "%ld", reached), check));
        } else {
            igraph_vector_int_t order; igraph_vector_int_init(&order, 0);
            MEASURE(k, { igraph_vector_int_destroy(&order); igraph_vector_int_init(&order, 0);
                igraph_dfs(&gr, 0, IGRAPH_OUT, 0, &order, NULL, NULL, NULL, NULL, NULL, NULL); });
            for (long i = 0; i < igraph_vector_int_size(&order); ++i) reached += VECTOR(order)[i] >= 0;
            report("igraph_t (igraph_dfs)", (snprintf(check, sizeof check, "%ld", reached), check));
        }
    } else if (IS("cc") || IS("scc")) {
        int strong = IS("scc");
        igraph_t gr; make(&g, strong, 0, &gr);
        igraph_integer_t no = 0;
        MEASURE(k, { igraph_vector_int_t mem; igraph_vector_int_init(&mem, 0);
            igraph_connected_components(&gr, &mem, NULL, &no, strong ? IGRAPH_STRONG : IGRAPH_WEAK);
            igraph_vector_int_destroy(&mem); });
        snprintf(check, sizeof check, "%ld", (long)no);
        report("igraph_t", check);
    } else if (IS("dijkstra") || IS("bellman-ford")) {
        igraph_t gr; make(&g, 1, 0, &gr);
        igraph_vector_t w; weights(&g, &w);
        int dijkstra = IS("dijkstra");
        long reached = 0; double sum = 0;
        igraph_matrix_t res; igraph_matrix_init(&res, 0, 0);
        MEASURE(k, { igraph_matrix_destroy(&res); igraph_matrix_init(&res, 0, 0);
            if (dijkstra) igraph_distances_dijkstra(&gr, &res, igraph_vss_1(0), igraph_vss_all(), &w, IGRAPH_OUT);
            else igraph_distances_bellman_ford(&gr, &res, igraph_vss_1(0), igraph_vss_all(), &w, IGRAPH_OUT); });
        for (long i = 0; i < g.n; ++i) { double d = MATRIX(res, 0, i); if (isfinite(d)) { ++reached; sum += d; } }
        snprintf(check, sizeof check, "%ld,%.0f", reached, sum);
        report("igraph_t (double weights, 1×n matrix)", check);
    } else if (IS("mst-kruskal") || IS("mst-prim")) {
        igraph_t gr; make(&g, 0, 0, &gr);
        igraph_vector_t w; weights(&g, &w);
        igraph_mst_algorithm_t method = IS("mst-kruskal") ? IGRAPH_MST_KRUSKAL : IGRAPH_MST_PRIM;
        long count = 0; double sum = 0;
        igraph_vector_int_t res; igraph_vector_int_init(&res, 0);
        MEASURE(k, { igraph_vector_int_destroy(&res); igraph_vector_int_init(&res, 0);
            igraph_minimum_spanning_tree(&gr, &res, &w, method); });
        count = igraph_vector_int_size(&res);
        for (long i = 0; i < count; ++i) sum += VECTOR(w)[VECTOR(res)[i]];
        snprintf(check, sizeof check, "%ld,%.0f", count, sum);
        report("igraph_t (double weights)", check);
    } else if (IS("topo")) {
        igraph_t gr; make(&g, 1, 0, &gr);
        long *order = malloc(sizeof(long) * g.n), len = 0;
        igraph_vector_int_t res; igraph_vector_int_init(&res, 0);
        MEASURE(k, { igraph_vector_int_destroy(&res); igraph_vector_int_init(&res, 0);
            igraph_topological_sorting(&gr, &res, IGRAPH_OUT); });
        len = igraph_vector_int_size(&res);
        for (long i = 0; i < len && i < g.n; ++i) order[i] = VECTOR(res)[i];
        long *pos = malloc(sizeof(long) * g.n);
        for (long i = 0; i < g.n; ++i) pos[i] = -1;
        for (long i = 0; i < len; ++i) pos[order[i]] = i;
        int ok = len == g.n;
        for (long e = 0; ok && e < g.m; ++e) ok = pos[g.u[e]] < pos[g.v[e]];
        if (ok) snprintf(check, sizeof check, "valid,%ld", len); else snprintf(check, sizeof check, "invalid");
        report("igraph_t", check);
    } else if (IS("maxflow-pr") || IS("maxflow-value")) {
        igraph_t gr; make(&g, 1, 0, &gr);
        igraph_vector_t cap; weights(&g, &cap);
        int full = IS("maxflow-pr");
        double value = 0;
        MEASURE(k, {
            if (full) { igraph_vector_t flow; igraph_vector_init(&flow, 0);
                igraph_maxflow(&gr, &value, &flow, NULL, NULL, NULL, g.s, g.t, &cap, NULL);
                igraph_vector_destroy(&flow); }
            else igraph_maxflow_value(&gr, &value, g.s, g.t, &cap, NULL); });
        snprintf(check, sizeof check, "%.0f", value);
        report(full ? "igraph_t (igraph_maxflow with flow)" : "igraph_t (igraph_maxflow_value)", check);
    } else if (IS("bip-matching")) {
        igraph_t gr; make(&g, 0, 0, &gr);
        igraph_vector_bool_t types; igraph_vector_bool_init(&types, g.n);
        for (long i = g.nleft; i < g.n; ++i) VECTOR(types)[i] = 1;
        igraph_integer_t size = 0;
        MEASURE(k, { igraph_vector_int_t mate; igraph_vector_int_init(&mate, 0);
            igraph_maximum_bipartite_matching(&gr, &types, &size, NULL, &mate, NULL, 0);
            igraph_vector_int_destroy(&mate); });
        snprintf(check, sizeof check, "%ld", (long)size);
        report("igraph_t", check);
    } else if (IS("iso")) {
        igraph_t a, b; make(&g, 0, 0, &a); make(&g, 0, 1, &b);
        igraph_bool_t iso = 0;
        MEASURE(k, { igraph_isomorphic_vf2(&a, &b, NULL, NULL, NULL, NULL, &iso, NULL, NULL, NULL, NULL, NULL); });
        report("igraph_t (igraph_isomorphic_vf2)", iso ? "1" : "0");
    } else if (IS("bc")) {
        igraph_t gr; make(&g, 0, 0, &gr);
        double sum = 0;
        igraph_vector_t res; igraph_vector_init(&res, 0);
        MEASURE(k, { igraph_vector_destroy(&res); igraph_vector_init(&res, 0);
            igraph_betweenness(&gr, NULL, &res, igraph_vss_all(), 0, 0); });
        for (long i = 0; i < g.n; ++i) sum += VECTOR(res)[i];
        snprintf(check, sizeof check, "%.12e", sum);
        report("igraph_t", check);
    } else if (IS("pagerank")) {
        igraph_t gr; make(&g, 1, 0, &gr);
        double checksum = 0;
        igraph_vector_t res; igraph_vector_init(&res, 0); igraph_real_t value;
        MEASURE(k, { igraph_vector_destroy(&res); igraph_vector_init(&res, 0);
            igraph_pagerank(&gr, NULL, &res, &value, 0.85, 1, igraph_vss_all(), IGRAPH_PAGERANK_ALGO_PRPACK, NULL); });
        double total = 0; for (long i = 0; i < g.n; ++i) total += VECTOR(res)[i];
        for (long i = 0; i < g.n; ++i) checksum += VECTOR(res)[i] / total * (double)(i % 97 + 1);
        snprintf(check, sizeof check, "%.12e", checksum);
        report("igraph_t (PRPACK)", check);
    } else if (IS("triangles")) {
        igraph_t gr; make(&g, 0, 0, &gr);
        igraph_real_t count = 0;
        MEASURE(k, { igraph_count_triangles(&gr, &count); });
        snprintf(check, sizeof check, "%.0f", count);
        report("igraph_t", check);
    } else if (IS("transitivity")) {
        igraph_t gr; make(&g, 0, 0, &gr);
        igraph_real_t x = 0;
        MEASURE(k, { igraph_transitivity_undirected(&gr, &x, IGRAPH_TRANSITIVITY_ZERO); });
        snprintf(check, sizeof check, "%.12e", x);
        report("igraph_t", check);
    } else if (IS("articulation") || IS("bridges")) {
        igraph_t gr; make(&g, 0, 0, &gr);
        int art = IS("articulation");
        long count = 0;
        MEASURE(k, { igraph_vector_int_t res; igraph_vector_int_init(&res, 0);
            if (art) igraph_articulation_points(&gr, &res); else igraph_bridges(&gr, &res);
            count = igraph_vector_int_size(&res); igraph_vector_int_destroy(&res); });
        snprintf(check, sizeof check, "%ld", count);
        report("igraph_t", check);
    } else if (IS("fw")) {
        igraph_t gr; make(&g, 1, 0, &gr);
        igraph_vector_t w; weights(&g, &w);
        long finite = 0; double sum = 0;
        igraph_matrix_t res; igraph_matrix_init(&res, 0, 0);
        MEASURE(k, { igraph_matrix_destroy(&res); igraph_matrix_init(&res, 0, 0);
            igraph_distances_floyd_warshall(&gr, &res, igraph_vss_all(), igraph_vss_all(), &w, IGRAPH_OUT, IGRAPH_FLOYD_WARSHALL_AUTOMATIC); });
        for (long i = 0; i < g.n; ++i) for (long j = 0; j < g.n; ++j) { double d = MATRIX(res, i, j); if (isfinite(d)) { ++finite; sum += d; } }
        snprintf(check, sizeof check, "%ld,%.0f", finite, sum);
        report("igraph_t (double weights)", check);
    } else if (IS("matching")) {
        printf("NA maximum matching is implemented for bipartite graphs only\n");
    } else if (IS("maxflow-dinic")) {
        printf("NA no Dinic (push-relabel only)\n");
    } else if (IS("insert") || IS("insert-walk") || IS("remove")) {
        printf("NA igraph_add_edge and igraph_delete_edges rebuild the edge index per call, O(n + m) each\n");
    } else {
        printf("NA not in igraph\n");
    }
    return 0;
}
