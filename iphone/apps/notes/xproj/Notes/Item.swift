import Foundation
import SwiftData

// SwiftData-backed domain types for Notes.
//
// The surrounding UI treats folders as the primary organizational unit; a note
// belongs to exactly one folder and carries either an "active" or "trashed"
// status flag. The persistent-model shape intentionally mirrors Apple's Notes
// app so that an agent exploring via accessibility IDs sees predictable
// sections (Pinned / Notes / Recently Deleted) without surprises.

@Model
final class Note {
    var title: String
    var body: String
    var createdDate: Date
    var modifiedDate: Date
    var isPinned: Bool
    var isInTrash: Bool
    var trashedDate: Date?
    var folder: NoteFolder?

    init(
        title: String = "",
        body: String = "",
        createdDate: Date = .now,
        modifiedDate: Date? = nil,
        isPinned: Bool = false
    ) {
        self.title = title
        self.body = body
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate ?? createdDate
        self.isPinned = isPinned
        self.isInTrash = false
        self.trashedDate = nil
    }
}

@Model
final class NoteFolder {
    var name: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \Note.folder)
    var notes: [Note]

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
        self.notes = []
    }
}

// MARK: - Display helpers

extension Note {
    var resolvedTitle: String {
        title.isEmpty ? "New Note" : title
    }

    var displayTitle: String { resolvedTitle }

    func firstNonEmptyLine(truncatedTo limit: Int = 80) -> String {
        for line in body.split(whereSeparator: { $0.isNewline }) {
            let candidate = line.trimmingCharacters(in: .whitespaces)
            if !candidate.isEmpty {
                return String(candidate.prefix(limit))
            }
        }
        return ""
    }

    var preview: String { firstNonEmptyLine() }

    /// Accessibility identifier used to locate a note row via MCP.
    /// Stable across renders (derived from the display title, not the
    /// SwiftData persistentModelID, so agents can target notes by name).
    var rowAccessibilityID: String {
        let slug = resolvedTitle
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .prefix(50)
        return "note_row_\(slug)"
    }
}

extension NoteFolder {
    var activeNotes: [Note] {
        notes.filter { !$0.isInTrash }
    }

    var accessibilityID: String {
        let slug = name.lowercased().replacingOccurrences(of: " ", with: "_")
        return "notes_folder_\(slug)"
    }
}
