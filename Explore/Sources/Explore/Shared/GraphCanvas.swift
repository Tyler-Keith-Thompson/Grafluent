import ElementaryUI

/// A vertex on a canvas: where it sits, its circle's radius, the text in the circle, the name
/// under it and a second line under that, and the CSS classes that colour it.
struct CanvasNode {
    var x: Double
    var y: Double
    var name: String
    var badge: String = ""
    var note: String = ""
    var radius: Double = 14
    var classes: String = ""
    /// Where the name goes: under the circle, or above it.
    var nameAbove = false
}

/// An edge on a canvas between two node offsets: its classes, a label at its middle, an arrow
/// at `to` when directed, and a sideways bend (in view-box units) so two opposite edges between
/// the same pair do not overlap.
struct CanvasEdge {
    var from: Int
    var to: Int
    var directed = false
    var label: String = ""
    var classes: String = ""
    var bend: Double = 0
}

/// A drawn graph. Nodes carry `data-node`, edges `data-edge`, so a click or Enter on either
/// reaches `onNode` or `onEdge` with its offset.
@View
struct GraphCanvas {
    var label: String
    var width: Int
    var height: Int
    var nodes: [CanvasNode]
    var edges: [CanvasEdge]
    var onNode: ((Int) -> Void)? = nil
    var onEdge: ((Int) -> Void)? = nil
    var nodeAction: String = ""

    var body: some View {
        let onNode = onNode, onEdge = onEdge
        SVG.svg(.class("canvas"), .viewBox(0, 0, .init(width), .init(height)), .custom(name: "role", value: "img"), .custom(name: "aria-label", value: label)) {
            for (i, edge) in edges.enumerated() {
                let shape = EdgeShape(edge, nodes[edge.from], nodes[edge.to])
                SVG.g(.class("edge " + edge.classes + (onEdge == nil ? "" : " clickable")), .data("edge", value: "\(i)")) {
                    SVG.path(.d(shape.path), .class("hit")) {}
                    SVG.path(.d(shape.path), .class("stroke")) {}
                    if edge.directed {
                        SVG.polygon(.points(shape.arrowhead), .class("head")) {}
                    }
                    if !edge.label.isEmpty {
                        SVG.text(.x(.init(shape.labelX)), .y(.init(shape.labelY)), .textAnchor("middle"), .class("weight")) { edge.label }
                    }
                }
            }
            for (i, node) in nodes.enumerated() {
                let nameY = node.nameAbove ? node.y - node.radius - 8 : node.y + node.radius + 18
                SVG.g(.class("node " + node.classes + (onNode == nil ? "" : " clickable")), .data("node", value: "\(i)"),
                      .custom(name: "tabindex", value: onNode == nil ? "-1" : "0"), .custom(name: "role", value: onNode == nil ? "presentation" : "button"),
                      .custom(name: "aria-label", value: nodeAction.isEmpty ? node.name : "\(nodeAction) \(node.name)")) {
                    SVG.circle(.cx(.init(node.x)), .cy(.init(node.y)), .r(.init(node.radius))) {}
                    if !node.badge.isEmpty {
                        SVG.text(.x(.init(node.x)), .y(.init(node.y + 5)), .textAnchor("middle"), .class("badge")) { node.badge }
                    }
                    if !node.name.isEmpty {
                        SVG.text(.x(.init(node.x)), .y(.init(nameY)), .textAnchor("middle"), .class("name")) { node.name }
                    }
                    if !node.note.isEmpty {
                        SVG.text(.x(.init(node.x)), .y(.init(node.nameAbove ? node.y + node.radius + 18 : nameY + 17)), .textAnchor("middle"), .class("note")) { node.note }
                    }
                }
            }
        }
        ._onEvent(ClickEvent.self) { event in
            if let i = event.integer("data-node") {
                onNode?(i)
            } else if let i = event.integer("data-edge") {
                onEdge?(i)
            }
        }
        ._onEvent(KeyDownEvent.self) { event in
            guard event.key == "Enter" || event.key == " ", let i = event.integer("data-node"), let onNode else { return }
            event.preventDefault()
            onNode(i)
        }
    }
}

/// The path of an edge, from just outside one circle to just outside the other, bent sideways
/// by `bend`; its arrowhead; and where its label goes.
struct EdgeShape {
    var path: String
    var arrowhead: String
    var labelX: Double
    var labelY: Double

    init(_ edge: CanvasEdge, _ a: CanvasNode, _ b: CanvasNode) {
        let dx = b.x - a.x, dy = b.y - a.y
        let length = max((dx * dx + dy * dy).squareRoot(), 1)
        // The unit normal, to the left going from a to b.
        let nx = -dy / length, ny = dx / length
        let cx = (a.x + b.x) / 2 + nx * edge.bend * 2, cy = (a.y + b.y) / 2 + ny * edge.bend * 2
        func toward(_ x: Double, _ y: Double, from px: Double, _ py: Double, by r: Double) -> (Double, Double) {
            let ux = x - px, uy = y - py
            let l = max((ux * ux + uy * uy).squareRoot(), 1)
            return (px + ux / l * r, py + uy / l * r)
        }
        // A node of radius 0 is a bend point: the edge runs right up to it.
        let start = toward(cx, cy, from: a.x, a.y, by: a.radius == 0 ? 0 : a.radius + 2)
        let end = toward(cx, cy, from: b.x, b.y, by: b.radius == 0 ? 0 : b.radius + (edge.directed ? 3 : 2))
        func f(_ v: Double) -> String { String(Double(Int((v * 10).rounded())) / 10) }
        path = edge.bend == 0
            ? "M\(f(start.0)),\(f(start.1)) L\(f(end.0)),\(f(end.1))"
            : "M\(f(start.0)),\(f(start.1)) Q\(f(cx)),\(f(cy)) \(f(end.0)),\(f(end.1))"
        // The arrowhead points along the curve's last direction.
        let tx = end.0 - (edge.bend == 0 ? start.0 : cx), ty = end.1 - (edge.bend == 0 ? start.1 : cy)
        let tl = max((tx * tx + ty * ty).squareRoot(), 1)
        let ux = tx / tl, uy = ty / tl
        let size = 11.0
        let baseX = end.0 - ux * size, baseY = end.1 - uy * size
        arrowhead = "\(f(end.0)),\(f(end.1)) \(f(baseX - uy * size * 0.5)),\(f(baseY + ux * size * 0.5)) \(f(baseX + uy * size * 0.5)),\(f(baseY - ux * size * 0.5))"
        // The label sits at the curve's middle, nudged off the line.
        let mx = edge.bend == 0 ? (a.x + b.x) / 2 : (a.x + b.x) / 4 + cx / 2
        let my = edge.bend == 0 ? (a.y + b.y) / 2 : (a.y + b.y) / 4 + cy / 2
        let side = edge.bend < 0 ? -1.0 : 1.0
        labelX = mx + nx * 13 * side
        labelY = my + ny * 13 * side + 5
    }
}
