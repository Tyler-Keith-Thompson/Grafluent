// snippet: layered-imports
import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Trees
// snippet end

// The build pipeline and the org chart of the layered drawing page, and the calls it makes. The
// marked regions are its code panels.

// snippet: layered-pipeline
let pipelineSteps = [
    DirectedEdge(from: "fetch", to: "compile"), DirectedEdge(from: "fetch", to: "lint"),
    DirectedEdge(from: "config", to: "compile"), DirectedEdge(from: "compile", to: "test"),
    DirectedEdge(from: "lint", to: "test"), DirectedEdge(from: "compile", to: "docs"),
    DirectedEdge(from: "test", to: "package"), DirectedEdge(from: "docs", to: "package"),
    DirectedEdge(from: "config", to: "package"), DirectedEdge(from: "package", to: "release"),
    DirectedEdge(from: "lint", to: "release"),
]
// snippet end

/// The pipeline, with a nightly rerun from release back to fetch when `rerun` is true.
func pipeline(rerun: Bool) -> AdjacencyList<String> {
    // snippet: layered-graph
    let pipeline = AdjacencyList<String> {
        for step in pipelineSteps { step }
        if rerun { DirectedEdge(from: "release", to: "fetch") }
    }
    // snippet end
    return pipeline
}

/// Sugiyama's layered drawing of `pipeline`.
func pipelineDrawing(_ pipeline: AdjacencyList<String>) -> LayeredDrawing<AdjacencyList<String>> {
    // snippet: layered-sugiyama
    let layered = pipeline.sugiyamaLayout()
    let crossings = layered.crossingCount                                    // →
    let reversed = layered.reversedEdges.map { pipeline.edges[$0] }          // →
    let layers = pipeline.vertices.map { "\($0): \(layered.layer(of: $0))" }  // →
    // snippet end
    _ = (crossings, reversed, layers)
    return layered
}

// snippet: layered-team
let reportsTo = [
    ("Ana", "CEO"), ("Raj", "CEO"), ("Mei", "CEO"),
    ("Tom", "Ana"), ("Sue", "Ana"), ("Kim", "Raj"),
    ("Lee", "Mei"), ("Bo", "Mei"), ("Ida", "Mei"),
    ("Ned", "Tom"), ("Ola", "Kim"), ("Pam", "Kim"), ("Quin", "Kim"),
]

let team = RootedTree(UndirectedAdjacencyList<String> {
    for (person, boss) in reportsTo { UndirectedEdge(boss, person) }
}, root: "CEO")!
// snippet end

/// The tidy drawing of the org chart, or its circular form.
func teamDrawing(circular: Bool) -> Drawing<String> {
    if circular {
        // snippet: layered-circular
        let drawing = team.reingoldTilfordCircularLayout()
        // snippet end
        return drawing
    }
    // snippet: layered-tidy
    let drawing = team.reingoldTilfordLayout()
    // snippet end
    return drawing
}
