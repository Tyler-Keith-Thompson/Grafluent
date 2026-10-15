import ElementaryUI
import JavaScriptKit

// ElementaryUI attaches event handlers to HTML views and to an `svg` element, not to the shapes
// inside one. The map and the timeline therefore listen on their `svg` and find the place or
// marble from the event's target, which carries a `data-place` or `data-step` attribute.

/// A DOM event as its JavaScript object.
struct DOMEventObject: _TypedDOMEvent {
    let object: JSObject

    init?(__jsObject object: JSObject) {
        self.object = object
    }

    /// The integer in attribute `name` of the nearest element at or above the event's target
    /// that has it.
    func integer(_ name: String) -> Int? {
        guard let target = object.target.object,
              let holder = target.closest?("[\(name)]").object,
              let text = holder.getAttribute?(name).string else { return nil }
        return Int(text)
    }

    /// The pressed key, for a keyboard event.
    var key: String { object.key.string ?? "" }

    func preventDefault() {
        _ = object.preventDefault?()
    }
}

enum ClickEvent: _DOMEventHandlerConfig {
    typealias Event = DOMEventObject
    static var name: String { "click" }
}

enum KeyDownEvent: _DOMEventHandlerConfig {
    typealias Event = DOMEventObject
    static var name: String { "keydown" }
}

enum PointerDownEvent: _DOMEventHandlerConfig {
    typealias Event = DOMEventObject
    static var name: String { "pointerdown" }
}

enum PointerMoveEvent: _DOMEventHandlerConfig {
    typealias Event = DOMEventObject
    static var name: String { "pointermove" }
}

enum PointerUpEvent: _DOMEventHandlerConfig {
    typealias Event = DOMEventObject
    static var name: String { "pointerup" }
}

extension DOMEventObject {
    /// Where the pointer is in the view box of the `svg` listening for the event, whose view
    /// box is `width` wide: the drawn size scales evenly, so one ratio converts both axes.
    func viewBoxPoint(width: Double) -> (x: Double, y: Double)? {
        guard let svg = object.currentTarget.object,
              let rect = svg.getBoundingClientRect?().object,
              let left = rect.left.number, let top = rect.top.number, let shown = rect.width.number, shown > 0,
              let x = object.clientX.number, let y = object.clientY.number else { return nil }
        let scale = width / shown
        return ((x - left) * scale, (y - top) * scale)
    }

    /// Keeps sending this pointer's events to the listening element until it is released.
    func capturePointer() {
        guard let svg = object.currentTarget.object, let id = object.pointerId.number else { return }
        _ = svg.setPointerCapture?(id)
    }
}
