/// Text the pages share: lists of names, and numbers in prose.

/// `Ana, Ben and Cy`; one name alone; nothing for no names.
func nameList(_ names: [String]) -> String {
    names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
}

/// `nameList`, but `nobody` for no names.
func guestList(_ names: [String]) -> String {
    names.isEmpty ? "nobody" : nameList(names)
}

/// `3`, `2.5` or `0.33`.
func shareText(_ x: Double) -> String {
    let hundredths = Int((x * 100).rounded())
    let whole = hundredths / 100, rest = hundredths % 100
    if rest == 0 { return "\(whole)" }
    return rest % 10 == 0 ? "\(whole).\(rest / 10)" : "\(whole).\(rest < 10 ? "0" : "")\(rest)"
}

/// `0.42` or `−0.08`, to two places.
func signedTwoPlaces(_ x: Double) -> String {
    let hundredths = Int((abs(x) * 100).rounded())
    return (x < 0 && hundredths > 0 ? "−" : "") + "\(hundredths / 100).\(hundredths % 100 < 10 ? "0" : "")\(hundredths % 100)"
}
