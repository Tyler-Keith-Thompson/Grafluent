//! petgraph and rustworkx-core harness: `cross-rust <library> <algorithm> <instance> <repeats>`,
//! where library is `petgraph` or `rustworkx-core`. Same output protocol as the other harnesses:
//! `RESULT <representation> <check> <ms,ms,…>` or `NA <reason>`.
//!
//! petgraph runs on `Graph` (its adjacency list with dense indices); rustworkx-core on
//! `StableGraph`, the representation rustworkx itself uses. Run with RAYON_NUM_THREADS=1 (run.py
//! sets it): rustworkx-core's transitivity is a rayon `par_iter`.

use std::convert::Infallible;
use std::hint::black_box;
use std::time::Instant;

use petgraph::graph::{DiGraph, NodeIndex, UnGraph};
use petgraph::stable_graph::{StableDiGraph, StableUnGraph};
use petgraph::visit::{Bfs, Dfs};

struct Instance {
    n: usize,
    m: usize,
    s: usize,
    t: usize,
    blocks: usize,
    u: Vec<usize>,
    v: Vec<usize>,
    w: Vec<i64>,
    u2: Vec<usize>,
    v2: Vec<usize>,
}

fn load(path: &str) -> Instance {
    let bytes = std::fs::read(path).expect("cannot read instance");
    let mut i = 0usize;
    let mut next = || -> u64 {
        while !bytes[i].is_ascii_digit() {
            i += 1;
        }
        let mut x = 0u64;
        while i < bytes.len() && bytes[i].is_ascii_digit() {
            x = x * 10 + (bytes[i] - b'0') as u64;
            i += 1;
        }
        x
    };
    let n = next() as usize;
    let m = next() as usize;
    let s = next() as usize;
    let t = next() as usize;
    let _nleft = next();
    let blocks = next() as usize;
    let (mut u, mut v, mut w) = (Vec::with_capacity(m), Vec::with_capacity(m), Vec::with_capacity(m));
    for _ in 0..m {
        u.push(next() as usize);
        v.push(next() as usize);
        w.push(next() as i64);
    }
    let (mut u2, mut v2) = (Vec::new(), Vec::new());
    if blocks > 1 {
        for _ in 0..m {
            u2.push(next() as usize);
            v2.push(next() as usize);
            next();
        }
    }
    Instance { n, m, s, t, blocks, u, v, w, u2, v2 }
}

fn measure<R>(repeats: usize, mut body: impl FnMut() -> R) -> (R, Vec<f64>) {
    let mut times = Vec::new();
    let mut last = None;
    for _ in 0..repeats {
        let start = Instant::now();
        let r = body();
        times.push(start.elapsed().as_secs_f64() * 1e3);
        last = Some(black_box(r));
    }
    (last.unwrap(), times)
}

fn report(rep: &str, check: String, times: &[f64]) {
    let t: Vec<String> = times.iter().map(|x| format!("{:.4}", x)).collect();
    println!("RESULT {} {} {}", rep, check, t.join(","));
}

fn float(x: f64) -> String {
    format!("{:.12e}", x)
}

fn digraph<W: Clone>(g: &Instance, w: &[W]) -> DiGraph<(), W> {
    let mut gr = DiGraph::with_capacity(g.n, g.m);
    for _ in 0..g.n {
        gr.add_node(());
    }
    for k in 0..g.m {
        gr.add_edge(NodeIndex::new(g.u[k]), NodeIndex::new(g.v[k]), w[k].clone());
    }
    gr
}

fn ungraph(n: usize, u: &[usize], v: &[usize], w: &[i64]) -> UnGraph<(), i64> {
    let mut gr = UnGraph::with_capacity(n, u.len());
    for _ in 0..n {
        gr.add_node(());
    }
    for k in 0..u.len() {
        gr.add_edge(NodeIndex::new(u[k]), NodeIndex::new(v[k]), w[k]);
    }
    gr
}

fn stable_digraph(g: &Instance) -> StableDiGraph<(), i64> {
    let mut gr = StableDiGraph::with_capacity(g.n, g.m);
    for _ in 0..g.n {
        gr.add_node(());
    }
    for k in 0..g.m {
        gr.add_edge(NodeIndex::new(g.u[k]), NodeIndex::new(g.v[k]), g.w[k]);
    }
    gr
}

fn stable_ungraph(g: &Instance) -> StableUnGraph<(), i64> {
    let mut gr = StableUnGraph::with_capacity(g.n, g.m);
    for _ in 0..g.n {
        gr.add_node(());
    }
    for k in 0..g.m {
        gr.add_edge(NodeIndex::new(g.u[k]), NodeIndex::new(g.v[k]), g.w[k]);
    }
    gr
}

fn topo_check(g: &Instance, order: Option<Vec<usize>>) -> String {
    match order {
        None => "cyclic".into(),
        Some(order) => {
            let mut pos = vec![usize::MAX; g.n];
            for (k, &x) in order.iter().enumerate() {
                pos[x] = k;
            }
            let ok = order.len() == g.n && (0..g.m).all(|k| pos[g.u[k]] < pos[g.v[k]]);
            if ok { format!("valid,{}", order.len()) } else { "invalid".into() }
        }
    }
}

fn petgraph_case(alg: &str, g: &Instance, k: usize) {
    let src = NodeIndex::new(0);
    match alg {
        "build-directed" => {
            let (gr, t) = measure(k, || digraph(g, &g.w));
            report("Graph", format!("{},{}", gr.node_count(), gr.edge_count()), &t);
        }
        "build-undirected" => {
            let (gr, t) = measure(k, || ungraph(g.n, &g.u, &g.v, &g.w));
            report("UnGraph", format!("{},{}", gr.node_count(), gr.edge_count()), &t);
        }
        "bfs" => {
            let gr = digraph(g, &g.w);
            let (c, t) = measure(k, || {
                let mut bfs = Bfs::new(&gr, src);
                let mut c = 0usize;
                while let Some(_) = bfs.next(&gr) {
                    c += 1;
                }
                c
            });
            report("Graph", c.to_string(), &t);
        }
        "dfs" => {
            let gr = digraph(g, &g.w);
            let (c, t) = measure(k, || {
                let mut dfs = Dfs::new(&gr, src);
                let mut c = 0usize;
                while let Some(_) = dfs.next(&gr) {
                    c += 1;
                }
                c
            });
            report("Graph", c.to_string(), &t);
        }
        "scc" => {
            let gr = digraph(g, &g.w);
            let (c, t) = measure(k, || petgraph::algo::tarjan_scc(&gr).len());
            report("Graph (tarjan_scc)", c.to_string(), &t);
        }
        "cc" => {
            let gr = ungraph(g.n, &g.u, &g.v, &g.w);
            let (c, t) = measure(k, || petgraph::algo::connected_components(&gr));
            report("UnGraph", c.to_string(), &t);
        }
        "dijkstra" => {
            let gr = digraph(g, &g.w);
            let (d, t) = measure(k, || petgraph::algo::dijkstra(&gr, src, None, |e| *e.weight()));
            let sum: i64 = d.values().sum();
            report("Graph", format!("{},{}", d.len(), sum), &t);
        }
        "bellman-ford" => {
            let wf: Vec<f64> = g.w.iter().map(|&x| x as f64).collect();
            let gr = digraph(g, &wf);
            let (p, t) = measure(k, || petgraph::algo::bellman_ford(&gr, src).unwrap());
            let (mut reached, mut sum) = (0usize, 0f64);
            for &d in &p.distances {
                if d.is_finite() {
                    reached += 1;
                    sum += d;
                }
            }
            report("Graph (f64 weights)", format!("{},{:.0}", reached, sum), &t);
        }
        "mst-kruskal" | "mst-prim" => {
            let gr = ungraph(g.n, &g.u, &g.v, &g.w);
            let tally = |it: &mut dyn Iterator<Item = petgraph::data::Element<(), i64>>| {
                let (mut c, mut s) = (0usize, 0i64);
                for e in it {
                    if let petgraph::data::Element::Edge { weight, .. } = e {
                        c += 1;
                        s += weight;
                    }
                }
                (c, s)
            };
            let ((c, s), t) = if alg == "mst-kruskal" {
                measure(k, || tally(&mut petgraph::algo::min_spanning_tree(&gr)))
            } else {
                measure(k, || tally(&mut petgraph::algo::min_spanning_tree_prim(&gr)))
            };
            report("UnGraph", format!("{},{}", c, s), &t);
        }
        "topo" => {
            let gr = digraph(g, &g.w);
            let (o, t) = measure(k, || petgraph::algo::toposort(&gr, None));
            report("Graph", topo_check(g, o.ok().map(|o| o.into_iter().map(|x| x.index()).collect())), &t);
        }
        "maxflow-dinic" => {
            let caps: Vec<u64> = g.w.iter().map(|&x| x as u64).collect();
            let gr = digraph(g, &caps);
            let (s, tt) = (NodeIndex::new(g.s), NodeIndex::new(g.t));
            let (f, t) = measure(k, || petgraph::algo::dinics(&gr, s, tt).0);
            report("Graph", f.to_string(), &t);
        }
        "matching" | "bip-matching" => {
            let gr = ungraph(g.n, &g.u, &g.v, &g.w);
            let (c, t) = measure(k, || petgraph::algo::maximum_matching(&gr).len());
            let rep = if alg == "matching" { "UnGraph" } else { "UnGraph (general algorithm)" };
            report(rep, c.to_string(), &t);
        }
        "iso" => {
            let a = ungraph(g.n, &g.u, &g.v, &g.w);
            let b = ungraph(g.n, &g.u2, &g.v2, &g.w);
            let (r, t) = measure(k, || petgraph::algo::is_isomorphic(&a, &b));
            report("UnGraph (VF2)", (if r { "1" } else { "0" }).into(), &t);
        }
        "articulation" => {
            let gr = ungraph(g.n, &g.u, &g.v, &g.w);
            let (c, t) = measure(k, || petgraph::algo::articulation_points::articulation_points(&gr).len());
            report("UnGraph", c.to_string(), &t);
        }
        "bridges" => {
            let gr = ungraph(g.n, &g.u, &g.v, &g.w);
            let (c, t) = measure(k, || petgraph::algo::bridges(&gr).count());
            report("UnGraph", c.to_string(), &t);
        }
        "fw" => {
            let wf: Vec<f64> = g.w.iter().map(|&x| x as f64).collect();
            let gr = digraph(g, &wf);
            let (d, t) = measure(k, || petgraph::algo::floyd_warshall(&gr, |e| *e.weight()).unwrap());
            let (mut finite, mut sum) = (0usize, 0f64);
            for &x in d.values() {
                if x < f64::MAX && x.is_finite() {
                    finite += 1;
                    sum += x;
                }
            }
            report("Graph (f64 weights, HashMap result)", format!("{},{:.0}", finite, sum), &t);
        }
        "pagerank" => println!("NA page_rank is O(n^2) per iteration with a fixed iteration count"),
        "maxflow-pr" | "maxflow-value" => println!("NA no push-relabel (dinics and ford_fulkerson only)"),
        _ => println!("NA not in petgraph"),
    }
}

fn rustworkx_case(alg: &str, g: &Instance, k: usize) {
    use rustworkx_core::petgraph::visit::Control;
    let src = NodeIndex::new(0);
    match alg {
        "build-directed" => {
            let (gr, t) = measure(k, || stable_digraph(g));
            report("StableGraph", format!("{},{}", gr.node_count(), gr.edge_count()), &t);
        }
        "build-undirected" => {
            let (gr, t) = measure(k, || stable_ungraph(g));
            report("StableGraph", format!("{},{}", gr.node_count(), gr.edge_count()), &t);
        }
        "bfs" => {
            let gr = stable_digraph(g);
            let (c, t) = measure(k, || {
                let mut c = 0usize;
                rustworkx_core::traversal::breadth_first_search(&gr, [src], |ev| {
                    if let rustworkx_core::traversal::BfsEvent::Discover(_) = ev {
                        c += 1;
                    }
                    Control::<()>::Continue
                });
                c
            });
            report("StableGraph", c.to_string(), &t);
        }
        "dfs" => {
            let gr = stable_digraph(g);
            let (c, t) = measure(k, || {
                let mut c = 0usize;
                rustworkx_core::traversal::depth_first_search(&gr, [src], |ev| {
                    if let rustworkx_core::traversal::DfsEvent::Discover(_, _) = ev {
                        c += 1;
                    }
                    Control::<()>::Continue
                });
                c
            });
            report("StableGraph", c.to_string(), &t);
        }
        "cc" => {
            let gr = stable_ungraph(g);
            let (c, t) = measure(k, || rustworkx_core::connectivity::number_connected_components(&gr));
            report("StableGraph", c.to_string(), &t);
        }
        "dijkstra" => {
            let gr = stable_digraph(g);
            let (d, t) = measure(k, || {
                let r: Result<Vec<Option<i64>>, Infallible> =
                    rustworkx_core::shortest_path::dijkstra(&gr, src, None, |e| Ok(*e.weight()), None);
                r.unwrap()
            });
            let (reached, sum) = d.iter().flatten().fold((0usize, 0i64), |(c, s), &x| (c + 1, s + x));
            report("StableGraph", format!("{},{}", reached, sum), &t);
        }
        "bellman-ford" => {
            let gr = stable_digraph(g);
            let (d, t) = measure(k, || {
                let r: Result<Option<Vec<Option<i64>>>, Infallible> =
                    rustworkx_core::shortest_path::bellman_ford(&gr, src, |e| Ok(*e.weight()), None);
                r.unwrap().unwrap()
            });
            let (reached, sum) = d.iter().flatten().fold((0usize, 0i64), |(c, s), &x| (c + 1, s + x));
            report("StableGraph", format!("{},{}", reached, sum), &t);
        }
        "topo" => {
            let gr = stable_digraph(g);
            let (o, t) = measure(k, || {
                rustworkx_core::dag_algo::lexicographical_topological_sort(&gr, |x| Ok::<usize, Infallible>(x.index()), false, None)
            });
            report(
                "StableGraph (lexicographical_topological_sort)",
                topo_check(g, o.ok().map(|o| o.into_iter().map(|x| x.index()).collect())),
                &t,
            );
        }
        "matching" | "bip-matching" => {
            if g.n > 5000 {
                println!("NA max_weight_matching is the O(n^3) weighted blossom; skipped above 5000 vertices");
                return;
            }
            let gr = stable_ungraph(g);
            let (c, t) = measure(k, || {
                rustworkx_core::max_weight_matching::max_weight_matching(&gr, true, |_| Ok::<i128, Infallible>(1), false)
                    .unwrap()
                    .len()
            });
            report("StableGraph (max_weight_matching, unit weights)", c.to_string(), &t);
        }
        "bc" => {
            let gr = stable_ungraph(g);
            let (b, t) = measure(k, || rustworkx_core::centrality::betweenness_centrality(&gr, false, false, usize::MAX));
            let sum: f64 = b.iter().flatten().sum();
            report("StableGraph", float(sum), &t);
        }
        "transitivity" => {
            let gr = stable_ungraph(g);
            let (x, t) = measure(k, || rustworkx_core::transitivity::graph_transitivity(&gr));
            report("StableGraph", float(x), &t);
        }
        "articulation" => {
            let gr = stable_ungraph(g);
            let (c, t) = measure(k, || rustworkx_core::connectivity::articulation_points(&gr, None).len());
            report("StableGraph", c.to_string(), &t);
        }
        "bridges" => {
            let gr = stable_ungraph(g);
            let (c, t) = measure(k, || rustworkx_core::connectivity::bridges(&gr).len());
            report("StableGraph", c.to_string(), &t);
        }
        _ => println!("NA not in rustworkx-core"),
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 5 {
        eprintln!("usage: cross-rust <petgraph|rustworkx-core> <algorithm> <instance> <repeats>");
        std::process::exit(2);
    }
    let g = load(&args[3]);
    let _ = g.blocks;
    let k: usize = args[4].parse().unwrap();
    match args[1].as_str() {
        "petgraph" => petgraph_case(&args[2], &g, k),
        "rustworkx-core" => rustworkx_case(&args[2], &g, k),
        other => panic!("unknown library {other}"),
    }
}
