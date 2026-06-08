import Foundation

enum SlidesHomeSection: String, CaseIterable, Identifiable {
    case recent
    case starred
    case sharedWithMe
    case offline
    case spam
    case trash
    case googleDrive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            return "Recent"
        case .starred:
            return "Starred"
        case .sharedWithMe:
            return "Shared with me"
        case .offline:
            return "Offline"
        case .spam:
            return "Spam"
        case .trash:
            return "Trash"
        case .googleDrive:
            return "CloudDrive"
        }
    }

    var systemImage: String {
        switch self {
        case .recent:
            return "clock"
        case .starred:
            return "star.fill"
        case .sharedWithMe:
            return "person.2.fill"
        case .offline:
            return "checkmark.circle.fill"
        case .spam:
            return "exclamationmark.octagon"
        case .trash:
            return "trash.fill"
        case .googleDrive:
            return "externaldrive"
        }
    }
}

enum SlidesHomeSortOption: String, CaseIterable, Identifiable {
    case lastOpenedByMe
    case updated
    case name

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lastOpenedByMe:
            return "Last opened by me"
        case .updated:
            return "Last modified"
        case .name:
            return "Name"
        }
    }
}

@MainActor
struct SlidesHomeViewModel {
    let store: WorkspaceStore

    var profileInitials: String {
        let words = store.profile.displayName
            .split(separator: " ")
            .prefix(2)

        let initials = words
            .compactMap { $0.first }
            .map(String.init)
            .joined()

        return initials.isEmpty ? "L" : initials
    }

    func files(
        in section: SlidesHomeSection,
        query: String,
        sort: SlidesHomeSortOption
    ) -> [WorkspaceFile] {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        var files = store.currentData.files.filter { $0.fileType == .presentation }

        switch section {
        case .recent:
            files = files.filter { !$0.trashed }
        case .starred:
            files = files.filter { $0.starred && !$0.trashed }
        case .sharedWithMe:
            files = files.filter { $0.shared && !$0.trashed }
        case .offline:
            files = files.filter { !$0.trashed }
        case .spam:
            files = []
        case .trash:
            files = files.filter(\.trashed)
        case .googleDrive:
            files = files.filter { !$0.trashed }
        }

        if normalizedQuery.isEmpty == false {
            files = files.filter { file in
                if file.name.lowercased().contains(normalizedQuery) {
                    return true
                }

                if store.contentPreview(for: file).lowercased().contains(normalizedQuery) {
                    return true
                }

                guard let presentation = store.presentation(id: file.id) else {
                    return false
                }

                return presentation.slides.contains { slide in
                    slide.title.lowercased().contains(normalizedQuery) ||
                    slide.body.lowercased().contains(normalizedQuery)
                }
            }
        }

        switch sort {
        case .lastOpenedByMe:
            files.sort {
                ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt)
            }
        case .updated:
            files.sort { $0.updatedAt > $1.updatedAt }
        case .name:
            files.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return files
    }

    func presentation(for file: WorkspaceFile) -> PresentationFile? {
        store.presentation(id: file.id)
    }
}
