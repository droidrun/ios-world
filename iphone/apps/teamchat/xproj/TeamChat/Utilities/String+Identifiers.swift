import Foundation

extension String {
    var accessibilitySlug: String {
        lowercased()
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "")
    }
}
