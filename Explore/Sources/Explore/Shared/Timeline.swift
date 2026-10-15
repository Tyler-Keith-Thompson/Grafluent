import ElementaryUI

/// One event on a timeline: a circle of class `kind` and radius `radius`, an optional letter in
/// it, and the sentence its tooltip gives.
struct Marble {
    var kind: String
    var radius: Double
    var letter: String = ""
    var title: String = ""
}

/// The marble timeline: one marble per step, the playhead after the steps shown, a scrubber, and
/// a legend. Clicking a marble shows the steps up to and including it.
@View
struct Timeline {
    var playback: Playback
    var marbles: [Marble]
    var legend: [(marble: Marble, text: String)]

    var body: some View {
        let playback = playback
        let k = playback.k
        let gap = 26
        let width = max(marbles.count * gap + 30, 300)
        let playhead = k == 0 ? 9 : 22 + (k - 1) * gap
        div(.class("timeline-scroll")) {
            SVG.svg(.class("timeline"), .width(.init(width)), .viewBox(0, 0, .init(width), 64), .custom(name: "aria-label", value: "Timeline of events")) {
                SVG.line(.x1(8), .y1(32), .x2(.init(width - 8)), .y2(32), .class("axis")) {}
                for (i, marble) in marbles.enumerated() {
                    let x = 22 + i * gap
                    SVG.g(.class(i < k ? "marble past" : "marble future"), .data("step", value: "\(i)")) {
                        SVG.circle(.cx(.init(x)), .cy(32), .r(.init(marble.radius)), .class(marble.kind)) {}
                        if !marble.letter.isEmpty {
                            SVG.text(.x(.init(x)), .y(36), .textAnchor("middle")) { marble.letter }
                        }
                        SVG.title { marble.title }
                    }
                }
                SVG.line(.x1(.init(playhead)), .y1(8), .x2(.init(playhead)), .y2(56), .class("playhead")) {}
            }
            ._onEvent(ClickEvent.self) { event in
                guard let i = event.integer("data-step") else { return }
                playback.pause()
                playback.show(i + 1)
            }
        }
        input(.id(playback.scrubID), .class("scrub"), .type(.range), .min(0), .max(playback.count), .value("\(k)"), .custom(name: "aria-label", value: "Scrub through the steps"))
            .onInput { event in
                if let value = event.targetValue, let n = Int(value) {
                    playback.pause()
                    playback.show(n)
                }
            }
        div(.class("tl-legend")) {
            for entry in legend {
                span {
                    SVG.svg(.width(16), .height(16), .viewBox(0, 0, 16, 16), .class("swatch")) {
                        SVG.circle(.cx(8), .cy(8), .r(.init(min(entry.marble.radius, 7))), .class(entry.marble.kind)) {}
                    }
                    entry.text
                }
            }
        }
    }
}
