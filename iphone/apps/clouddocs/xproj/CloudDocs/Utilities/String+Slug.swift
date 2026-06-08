import Foundation

extension String {
    var stableSlug: String {
        let allowed = CharacterSet.alphanumerics
        let lowercased = self.lowercased()
        var pieces: [String] = []
        var current = ""

        for scalar in lowercased.unicodeScalars {
            if allowed.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if current.isEmpty == false {
                pieces.append(current)
                current = ""
            }
        }

        if current.isEmpty == false {
            pieces.append(current)
        }

        return pieces.isEmpty ? "item" : pieces.joined(separator: "_")
    }
}
