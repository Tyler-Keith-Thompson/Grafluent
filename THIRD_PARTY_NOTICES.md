# Third-party notices

Grafluent's test suite restates graph fixtures and expected values (degree sequences, edge counts,
graph definitions) found in the test suites of the projects below. These are mathematical facts
and are cited at each use. No code from these projects is copied. Testing techniques modeled on
swift-collections are independent reimplementations, credited in the files that use them.

| Project | License | Used for |
|---|---|---|
| [NetworkX](https://github.com/networkx/networkx) | BSD-3-Clause | Fixtures and expected values |
| [petgraph](https://github.com/petgraph/petgraph) | MIT OR Apache-2.0 | Fixtures, expected values, property-test ideas |
| [Boost.Graph](https://github.com/boostorg/graph) | BSL-1.0 | Fixtures, expected values, the seeded random-operations harness design |
| [JGraphT](https://github.com/jgrapht/jgrapht) | EPL-2.0 OR LGPL-2.1-or-later | Fixtures and expected values only (re-derived; no code translated) |
| [swift-collections](https://github.com/apple/swift-collections) | Apache-2.0 with Runtime Library Exception | Testing techniques: hidden copies, lifetime tracking, conformance checkers, minimal sequences, colliding keys |
