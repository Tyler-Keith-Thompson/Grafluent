# ParallelCentrality test suite

`ParallelCentrality` adds async spellings of `Centrality`'s betweenness, closeness and harmonic
centrality whose searches are shared among the tasks of a task group:
`betweennessCentrality(parallelism:normalized:endpoints:)`, its weighted form,
`closenessCentrality(parallelism:wfImproved:)` and `harmonicCentrality(parallelism:)` on `Graph`
and `DirectedGraph`, with `defaultParallelism` the processors online. The tests compare every
parallel measure with the sequential one on hand-worked and random graphs over several
representations, at one task, a few, and more tasks than vertices; closeness and harmonic agree
exactly and betweenness to rounding. `Performance/` bounds the parallel measure's time against the
sequential one. The suite uses only the public API, and each test is self-contained.
