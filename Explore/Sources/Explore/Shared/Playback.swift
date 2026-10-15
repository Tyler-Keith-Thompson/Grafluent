import ElementaryUI
import JavaScriptKit
import Reactivity

/// A playhead over a page's steps: how many have happened, and whether they play on their own.
/// The timeline, the scrubber and the playback buttons read and move it.
@Reactive
final class Playback {
    /// The number of steps shown, `0...count`.
    var k = 0
    var count = 0
    var playing = false
    @ReactiveIgnored var timer: JSTimer?
    @ReactiveIgnored let millisecondsPerStep: Double
    /// The id of the timeline's scrubber, unique on the page.
    @ReactiveIgnored let scrubID: String

    init(millisecondsPerStep: Double = 750, scrubID: String = "scrub") {
        self.millisecondsPerStep = millisecondsPerStep
        self.scrubID = scrubID
    }

    var isFinished: Bool { k == count }

    /// Starts over with `count` steps, at the beginning.
    func reset(count: Int) {
        pause()
        self.count = count
        show(0)
    }

    func show(_ n: Int) {
        k = max(0, min(count, n))
        setProperty(id: scrubID, "value", to: "\(k)")
    }

    func play() {
        if k >= count { show(0) }
        playing = true
        #if arch(wasm32)
        timer = JSTimer(millisecondsDelay: millisecondsPerStep, isRepeating: true) { [weak self] in
            guard let self else { return }
            if self.k >= self.count { self.pause() } else { self.show(self.k + 1) }
        }
        #endif
    }

    func pause() {
        timer = nil
        playing = false
    }

    func togglePlay() {
        if playing { pause() } else { play() }
    }

    func step(by offset: Int) {
        pause()
        show(k + offset)
    }
}

/// Back, play or pause, step and reset.
@View
struct PlaybackButtons {
    var playback: Playback

    var body: some View {
        let playback = playback
        button(.type(.button), .custom(name: "aria-label", value: "Step back")) { "◀ Back" }
            .onClick { playback.step(by: -1) }
        button(.type(.button), .class("primary")) { playback.playing ? "❚❚ Pause" : "▶ Play" }
            .onClick { playback.togglePlay() }
        button(.type(.button)) { "Step ▶" }
            .onClick { playback.step(by: 1) }
        button(.type(.button)) { "Reset" }
            .onClick {
                playback.pause()
                playback.show(0)
            }
    }
}

/// Sets a DOM property, for the controls whose shown value is the property rather than the
/// attribute once someone has used them: a select's value and a range input's value.
/// The build machine's first frames have no DOM, so there it does nothing.
func setProperty(id: String, _ name: String, to value: String) {
    #if arch(wasm32)
    guard let document = JSObject.global.document.object,
          let element = document.getElementById!(id).object else { return }
    element[name] = .string(value)
    #endif
}
