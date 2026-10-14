import AdjacencyListModule
import ElementaryUI
import GraphProtocols
import ShortestPaths

/// The explorer everywhere on the page reads this one model.
let explorer = Explorer()

/// `∞` or `n min`.
func minutesText(_ d: Int?) -> String {
    d.map { "\($0) min" } ?? "∞"
}

/// The sentence for one step, as the narration and a marble's tooltip give it.
func describe(_ step: Step) -> String {
    switch step {
    case .settle(let place, let d):
        return d == 0
            ? "Start at \(places[place].name). It takes 0 minutes to be where you already are, so it is settled first."
            : "\(places[place].name) has the smallest guess on the frontier, \(d) min. Nothing quicker can still arrive, so it is settled."
    case .check(let from, let to, let street, let offer, let previous, let better):
        let w = minutes[town.edges[street]]!
        let via = "\(places[from].name) → \(places[to].name)"
        return better
            ? "Check \(via): \(offer - w) + \(w) = \(offer) min, which beats \(minutesText(previous)). \(places[to].name)’s guess drops to \(offer) min."
            : "Check \(via): \(offer - w) + \(w) = \(offer) min, which doesn’t beat \(minutesText(previous)). Nothing changes."
    }
}

/// The map, the panels beside it, and the playback controls with the timeline.
@View
struct LabView {
    var body: some View {
        let model = explorer
        let k = model.k
        let steps = model.steps
        let state = model.snapshot(k)
        let last = k > 0 ? steps[k - 1] : nil
        let finished = k == steps.count
        let tree = Set(state.parent.compactMap { $0 })
        let route = finished && model.target >= 0 ? model.walk(to: model.target, in: state).streets : []
        let activeStreet = last.flatMap { step -> Int? in
            if case .check(_, _, let street, _, _, _) = step { return street }
            return nil
        } ?? -1
        let frontier = (0 ..< places.count)
            .filter { !state.settled[$0] && state.distance[$0] != nil }
            .sorted { (state.distance[$0]!, $0) < (state.distance[$1]!, $1) }
        let settledOrder = steps.prefix(k).compactMap { step -> (place: Int, distance: Int)? in
            if case .settle(let place, let d) = step { return (place, d) }
            return nil
        }
        let gap = 26
        let width = max(steps.count * gap + 30, 300)
        let playhead = k == 0 ? 9 : 22 + (k - 1) * gap

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Interactive map")) {
                div(.class("panel mapbox")) {
                    SVG.svg(.id("map"), .viewBox(0, 0, 640, 520), .custom(name: "role", value: "img"), .custom(name: "aria-label", value: "Map of a small town: places joined by streets labelled with walking minutes")) {
                        for street in town.edges.indices {
                            let edge = town.edges[street]
                            let a = places[placeIndex[edge.u]!], b = places[placeIndex[edge.v]!]
                            let classes = "road" + (tree.contains(street) && !route.contains(street) ? " tree" : "")
                                + (route.contains(street) ? " route" : "") + (street == activeStreet ? " active" : "")
                            SVG.line(.x1(.init(a.x)), .y1(.init(a.y)), .x2(.init(b.x)), .y2(.init(b.y)), .class(classes)) {}
                        }
                        for street in town.edges.indices {
                            let edge = town.edges[street]
                            let a = places[placeIndex[edge.u]!], b = places[placeIndex[edge.v]!]
                            SVG.text(.x(.init(Double(a.x + b.x) / 2 + 6)), .y(.init(Double(a.y + b.y) / 2 - 6)), .class("km"), .style("font-size:14px")) {
                                "\(minutes[edge]!)"
                            }
                        }
                        for (i, place) in places.enumerated() {
                            let classes = "city" + (state.settled[i] ? " settled" : "")
                                + (!state.settled[i] && state.distance[i] != nil ? " frontier" : "")
                                + (i == model.source ? " source" : "") + (last?.place == i ? " current" : "")
                            SVG.g(.class(classes), .custom(name: "tabindex", value: "0"), .custom(name: "role", value: "button"),
                                  .custom(name: "aria-label", value: "Start at \(place.name)"), .data("place", value: "\(i)")) {
                                SVG.circle(.cx(.init(place.x)), .cy(.init(place.y)), .r(14)) {}
                                SVG.text(.x(.init(place.x)), .y(.init(place.y + 34)), .textAnchor("middle"), .style("font-size:15px")) { place.name }
                                SVG.text(.x(.init(place.x)), .y(.init(place.y + 51)), .textAnchor("middle"), .class("dist"), .style("font-size:13px")) {
                                    state.distance[i].map { "\($0) min" } ?? ""
                                }
                            }
                        }
                    }
                    ._onEvent(ClickEvent.self) { event in
                        if let place = event.integer("data-place") { explorer.start(place) }
                    }
                    ._onEvent(KeyDownEvent.self) { event in
                        guard event.key == "Enter" || event.key == " ", let place = event.integer("data-place") else { return }
                        event.preventDefault()
                        explorer.start(place)
                    }
                    div(.class("legend")) {
                        span { i(.class("dot u")) {}; "not reached yet" }
                        span { i(.class("dot f")) {}; "frontier: a best guess so far" }
                        span { i(.class("dot s")) {}; "settled: the cheapest is known" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label"), .id("steplabel")) { finished ? "Done after \(steps.count) steps" : "Step \(k) of \(steps.count)" }
                        p(.class("narration"), .id("narration")) {
                            if k == 0 {
                                "Every place starts unknown except \(places[model.source].name), which takes no time to reach. Press Step to begin."
                            } else if finished {
                                "Every place is settled. The blue streets form the "
                                em { "shortest-path tree" }
                                ": each place reached the quickest way from \(places[model.source].name)."
                                if model.target >= 0 && model.target != model.source {
                                    " The red line is the quickest walk to \(places[model.target].name): \(state.distance[model.target].map { "\($0)" } ?? "∞") min."
                                }
                            } else {
                                describe(last!)
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Frontier, cheapest first" }
                        div(.class("queue"), .id("queue")) {
                            if frontier.isEmpty {
                                p(.class("empty")) { finished ? "Empty: nothing left to settle." : "Empty" }
                            }
                            for (j, place) in frontier.enumerated() {
                                div(.class(j == 0 ? "qrow top" : "qrow")) {
                                    span { places[place].name + (j == 0 ? " · next" : "") }
                                    span(.class("num")) { "\(state.distance[place]!) min" }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Settled" }
                        div(.class("settledlist"), .id("settled")) {
                            if settledOrder.isEmpty {
                                p(.class("empty")) { "None yet" }
                            }
                            for entry in settledOrder {
                                span(.class("chip")) {
                                    "\(places[entry.place].name) "
                                    span(.class("num")) { "\(entry.distance)" }
                                }
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    button(.id("back"), .type(.button), .custom(name: "aria-label", value: "Step back")) { "◀ Back" }
                        .onClick { explorer.step(by: -1) }
                    button(.id("play"), .type(.button), .class("primary")) { model.playing ? "❚❚ Pause" : "▶ Play" }
                        .onClick { explorer.togglePlay() }
                    button(.id("step"), .type(.button)) { "Step ▶" }
                        .onClick { explorer.step(by: 1) }
                    button(.id("reset"), .type(.button)) { "Reset" }
                        .onClick {
                            explorer.pause()
                            explorer.show(0)
                        }
                    span(.class("spacer")) {}
                    label(.class("field"), .for("source")) {
                        "Start at "
                        select(.id("source")) {
                            for (i, place) in places.enumerated() {
                                option(.value("\(i)")) { place.name }.attributes(.selected, when: i == model.source)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let place = Int(value) { explorer.start(place) }
                        }
                    }
                    label(.class("field"), .for("target")) {
                        "Show the walk to "
                        select(.id("target")) {
                            option(.value("-1")) { "none" }.attributes(.selected, when: model.target == -1)
                            for (i, place) in places.enumerated() {
                                option(.value("\(i)")) { place.name }.attributes(.selected, when: i == model.target)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let place = Int(value) { explorer.setTarget(place) }
                        }
                    }
                }
                div(.class("timeline-scroll")) {
                    SVG.svg(.id("timeline"), .width(.init(width)), .viewBox(0, 0, .init(width), 64), .custom(name: "aria-label", value: "Timeline of events")) {
                        SVG.line(.x1(8), .y1(32), .x2(.init(width - 8)), .y2(32), .class("axis")) {}
                        for (i, step) in steps.enumerated() {
                            let x = 22 + i * gap
                            SVG.g(.class(i < k ? "marble past" : "marble future"), .data("step", value: "\(i)")) {
                                switch step {
                                case .settle(let place, _):
                                    SVG.circle(.cx(.init(x)), .cy(32), .r(11), .class("settle")) {}
                                    SVG.text(.x(.init(x)), .y(36), .textAnchor("middle")) { String(places[place].name.prefix(1)) }
                                case .check(_, _, _, _, _, let better):
                                    if better {
                                        SVG.circle(.cx(.init(x)), .cy(32), .r(7), .class("better")) {}
                                    } else {
                                        SVG.circle(.cx(.init(x)), .cy(32), .r(4), .class("worse")) {}
                                    }
                                }
                                SVG.title { describe(step) }
                            }
                        }
                        SVG.line(.x1(.init(playhead)), .y1(8), .x2(.init(playhead)), .y2(56), .class("playhead")) {}
                    }
                    ._onEvent(ClickEvent.self) { event in
                        guard let i = event.integer("data-step") else { return }
                        explorer.pause()
                        explorer.show(i + 1)
                    }
                }
                input(.id("scrub"), .type(.range), .min(0), .max(steps.count), .value("\(k)"), .custom(name: "aria-label", value: "Scrub through the steps"))
                    .onInput { event in
                        if let value = event.targetValue, let n = Int(value) {
                            explorer.pause()
                            explorer.show(n)
                        }
                    }
                div(.class("tl-legend")) {
                    span {
                        SVG.svg(.width(14), .height(14)) { SVG.circle(.cx(7), .cy(7), .r(6), .fill("var(--sign)")) {} }
                        "a place is settled"
                    }
                    span {
                        SVG.svg(.width(14), .height(14)) { SVG.circle(.cx(7), .cy(7), .r(5), .fill("var(--sheet)"), .stroke("var(--signal)"), .strokeWidth(3)) {} }
                        "a street gives a quicker guess"
                    }
                    span {
                        SVG.svg(.width(14), .height(14)) { SVG.circle(.cx(7), .cy(7), .r(3.5), .fill("var(--road)")) {} }
                        "a street is checked, not quicker"
                    }
                }
                p(.class("note")) { "Click any place to start from it. Numbers on the streets are walking minutes." }
            }
        }
    }
}

/// The Swift above the code panel's comments is the source in Town.swift and Explorer.swift;
/// the comments are the results the app computed from it.
@View
struct CodePanel {
    var body: some View {
        let model = explorer
        let source = places[model.source].name
        let t = model.target >= 0 && model.target != model.source
            ? model.target
            : (model.source == placeIndex["Station"]! ? placeIndex["Home"]! : placeIndex["Station"]!)
        let name = places[t].name
        let walks = town.dijkstraShortestPaths(from: source) { minutes[town.edges[$0]]! }
        let distance = walks.distance(to: name).map { "\($0)" } ?? "nil"
        let stops = walks.path(to: name).map(Array.init) ?? []
        let header: [(text: String, kind: String?)] = [
            ("import", "k"),
            (" AdjacencyListModule\n", nil),
            ("import", "k"),
            (" GraphProtocols\n", nil),
            ("import", "k"),
            (" ShortestPaths\n\n", nil),
            ("let", "k"),
            (" minutes: [UndirectedEdge<String>: Int] = [\n", nil),
        ]
        let rows = streetOrder.flatMap { street -> [(text: String, kind: String?)] in [
            ("    UndirectedEdge(", nil),
            ("\"\(street.u)\"", "s"),
            (", ", nil),
            ("\"\(street.v)\"", "s"),
            ("): \(minutes[street]!),\n", nil),
        ]}
        let rest: [(text: String, kind: String?)] = [
            ("]\n\n", nil),
            ("let", "k"),
            (" town = UndirectedAdjacencyList<String> {\n    ", nil),
            ("for", "k"),
            (" street ", nil),
            ("in", "k"),
            (" minutes.keys { street }\n}\n\n", nil),
            ("let", "k"),
            (" events = Array(town.dijkstraSearch(from: ", nil),
            ("\"\(source)\"", "s"),
            (") { minutes[town.edges[$0]]! })\n", nil),
            ("events.count                                  ", nil),
            ("// \(model.events.count)", "c"),
            ("\nevents[0]                                     ", nil),
            ("// \(model.events.first.map { "\($0)" } ?? "")", "c"),
            ("\n\n", nil),
            ("let", "k"),
            (" walks = town.dijkstraShortestPaths(from: ", nil),
            ("\"\(source)\"", "s"),
            (") { minutes[town.edges[$0]]! }\n", nil),
            ("walks.distance(to: ", nil),
            ("\"\(name)\"", "s"),
            (")                 ", nil),
            ("// \(distance)", "c"),
            ("\nwalks.path(to: ", nil),
            ("\"\(name)\"", "s"),
            (").map(Array.init)     ", nil),
            ("// [\(stops.map { "\"\($0)\"" }.joined(separator: ", "))]", "c"),
        ]
        let segments = header + rows + rest
        span {
            for segment in segments {
                if let kind = segment.kind {
                    span(.class(kind)) { segment.text }
                } else {
                    segment.text
                }
            }
        }
    }
}
