import ElementaryUI

/// Mounts the sample beside every static figure on this page: each figure's `<pre>` has the id
/// named here.
func mountFigureSamples() {
    if present("fig-direction") { mountView(CodePanel(snippets: [.figureDirection], results: directionFigure()), in: "fig-direction") }
    if present("fig-weights") { mountView(CodePanel(snippets: [.figureWeights], results: weightsFigure()), in: "fig-weights") }
    if present("fig-walks") { mountView(CodePanel(snippets: [.figureWalks], results: walksFigure()), in: "fig-walks") }
    if present("fig-loops") { mountView(CodePanel(snippets: [.figureLoops], results: loopsFigure()), in: "fig-loops") }
    if present("fig-bowtie") { mountView(CodePanel(snippets: [.figureBowtie], results: bowtieFigure()), in: "fig-bowtie") }
    if present("fig-negative") { mountView(CodePanel(snippets: [.figureNegative], results: negativeFigure()), in: "fig-negative") }
}
