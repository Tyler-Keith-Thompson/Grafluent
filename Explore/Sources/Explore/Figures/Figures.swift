import ElementaryUI
import JavaScriptKit

/// Mounts the sample beside every static figure on this page: each figure's `<pre>` has the id
/// named here.
func mountFigureSamples() {
    guard let document = JSObject.global.document.object else { return }
    func present(_ id: String) -> Bool { document.getElementById!(id).object != nil }
    if present("fig-direction") { Application(CodePanel(snippets: [.figureDirection], results: directionFigure())).mount(in: "#fig-direction") }
    if present("fig-weights") { Application(CodePanel(snippets: [.figureWeights], results: weightsFigure())).mount(in: "#fig-weights") }
    if present("fig-walks") { Application(CodePanel(snippets: [.figureWalks], results: walksFigure())).mount(in: "#fig-walks") }
    if present("fig-loops") { Application(CodePanel(snippets: [.figureLoops], results: loopsFigure())).mount(in: "#fig-loops") }
    if present("fig-negative") { Application(CodePanel(snippets: [.figureNegative], results: negativeFigure())).mount(in: "#fig-negative") }
}
