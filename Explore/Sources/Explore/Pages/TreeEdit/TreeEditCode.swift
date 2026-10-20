// snippet: treeedit-imports
import GraphProtocols
import TreeAlgorithms
import Trees
// snippet end

// The org charts and the calls the tree edit distance page makes. The marked regions are its code
// panels.

// snippet: treeedit-charts
/// Last year's org chart, as who reports to whom, in order.
let lastYear: [String: [String]] = [
    "CEO": ["Eng", "Sales"], "Eng": ["Ana", "Bo", "Cy"], "Sales": ["Di"],
]

/// This year's: Cy moved to Sales, Bo left, and an Ops team appeared.
let thisYear: [String: [String]] = [
    "CEO": ["Eng", "Sales", "Ops"], "Eng": ["Ana"], "Sales": ["Di", "Cy"], "Ops": ["Eve"],
]

let oldChart = OrderedTree(root: "CEO") { lastYear[$0] ?? [] }!
let newChart = OrderedTree(root: "CEO") { thisYear[$0] ?? [] }!
// snippet end

/// The distance at unit costs, where substituting one person for another is free, and at the
/// costs the page uses: nothing to keep a name, 2 to change it, 1 to delete or insert.
func chartDistances() -> (unit: Int, named: Int) {
    // snippet: treeedit-distance
    let edits = oldChart.treeEditDistance(to: newChart)  // →
    let named = oldChart.treeEditDistance(
        to: newChart,
        substitutionCost: { old, new in old == new ? 0 : 2 },
        deletionCost: { _ in 1 }, insertionCost: { _ in 1 })  // →
    // snippet end
    return (edits, named)
}

/// The distance from any chart to this year's, at the named costs.
func distanceToThisYear(_ chart: [String: [String]]) -> Int {
    let tree = OrderedTree(root: "CEO") { chart[$0] ?? [] }!
    return tree.treeEditDistance(to: newChart, substitutionCost: { old, new in old == new ? 0 : 2 }, deletionCost: { _ in 1 }, insertionCost: { _ in 1 })
}
