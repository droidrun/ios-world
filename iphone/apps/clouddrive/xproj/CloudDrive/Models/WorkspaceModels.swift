import Foundation

enum WorkspaceSourceType: String, CaseIterable, Codable, Hashable, Identifiable {
    case seeded
    case bundledSnapshot
    case importedSnapshot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .seeded:
            return "Built-in workspace"
        case .bundledSnapshot:
            return "Workspace package"
        case .importedSnapshot:
            return "Imported package"
        }
    }

    var shortLabel: String {
        switch self {
        case .seeded:
            return "Built-in"
        case .bundledSnapshot:
            return "Package"
        case .importedSnapshot:
            return "Imported"
        }
    }
}

enum WorkspaceFileType: String, CaseIterable, Codable, Hashable, Identifiable {
    case document
    case spreadsheet
    case presentation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .document:
            return "Document"
        case .spreadsheet:
            return "Spreadsheet"
        case .presentation:
            return "Presentation"
        }
    }

    var systemImage: String {
        switch self {
        case .document:
            return "doc.text"
        case .spreadsheet:
            return "tablecells"
        case .presentation:
            return "menucard"
        }
    }

    var editorScheme: String {
        switch self {
        case .document:
            return "docssim"
        case .spreadsheet:
            return "sheetssim"
        case .presentation:
            return "slidessim"
        }
    }

    var accessibilityPrefix: String {
        switch self {
        case .document:
            return "doc"
        case .spreadsheet:
            return "sheet"
        case .presentation:
            return "slides"
        }
    }
}

enum AccessRole: String, CaseIterable, Codable, Hashable, Identifiable {
    case viewer
    case commenter
    case editor

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum SharedLinkVisibility: String, CaseIterable, Codable, Hashable, Identifiable {
    case restricted
    case anyoneWithLink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restricted:
            return "Restricted"
        case .anyoneWithLink:
            return "Anyone with link"
        }
    }
}

enum WorkspaceSortOption: String, CaseIterable, Codable, Hashable, Identifiable {
    case recent
    case name
    case type

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            return "Recent"
        case .name:
            return "Name"
        case .type:
            return "Type"
        }
    }
}

enum WorkspaceSearchFilter: String, CaseIterable, Codable, Hashable, Identifiable {
    case all
    case folders
    case documents
    case spreadsheets
    case presentations
    case starred
    case shared
    case trashed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .folders:
            return "Folders"
        case .documents:
            return "Docs"
        case .spreadsheets:
            return "Sheets"
        case .presentations:
            return "Slides"
        case .starred:
            return "Starred"
        case .shared:
            return "Shared"
        case .trashed:
            return "Trash"
        }
    }
}

enum DocumentParagraphStyle: String, CaseIterable, Codable, Hashable, Identifiable {
    case normal
    case heading
    case subheading
    case title

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal:
            return "Normal"
        case .heading:
            return "Heading"
        case .subheading:
            return "Subheading"
        case .title:
            return "Title"
        }
    }
}

enum DocumentListStyle: String, CaseIterable, Codable, Hashable, Identifiable {
    case none
    case bullets
    case numbered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "None"
        case .bullets:
            return "Bullets"
        case .numbered:
            return "Numbered"
        }
    }
}

enum DocumentAlignment: String, CaseIterable, Codable, Hashable, Identifiable {
    case leading
    case center
    case trailing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leading:
            return "Left"
        case .center:
            return "Center"
        case .trailing:
            return "Right"
        }
    }
}

enum SlideLayout: String, CaseIterable, Codable, Hashable, Identifiable {
    case titleBody
    case titleOnly
    case section

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleBody:
            return "Title + Body"
        case .titleOnly:
            return "Title Only"
        case .section:
            return "Section"
        }
    }
}

struct WorkspaceSnapshotMetadata: Codable, Hashable {
    var snapshotTimestamp: Date
    var providerLabel: String
    var description: String
}

struct UserWorkspaceProfile: Codable, Hashable {
    var id: String
    var displayName: String
    var email: String
    var storageUsedGB: Double
    var storageLimitGB: Double
}

struct WorkspaceContact: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
}

struct FilePermission: Identifiable, Codable, Hashable {
    var id: String
    var personName: String
    var role: AccessRole
}

struct SharedLinkSettings: Codable, Hashable {
    var visibility: SharedLinkVisibility
    var defaultRole: AccessRole
    var copyCount: Int
}

struct FileComment: Identifiable, Codable, Hashable {
    var id: String
    var authorName: String
    var body: String
    var createdAt: Date
}

struct RecentActivity: Identifiable, Codable, Hashable {
    var id: String
    var summary: String
    var targetFileId: String?
    var createdAt: Date
}

struct WorkspaceFolder: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var parentFolderId: String?
    var createdAt: Date
    var updatedAt: Date
    var starred: Bool
    var shared: Bool
    var trashed: Bool
    var ownerName: String
}

struct DocumentFormattingState: Codable, Hashable {
    var paragraphStyle: DocumentParagraphStyle
    var listStyle: DocumentListStyle
    var alignment: DocumentAlignment
    var bold: Bool
    var italic: Bool
    var underline: Bool
    var suggestionModeEnabled: Bool
}

struct DocumentBlock: Identifiable, Codable, Hashable {
    var id: String
    var text: String
    var paragraphStyle: DocumentParagraphStyle
}

struct DocumentFile: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var body: String
    var formatting: DocumentFormattingState
    var blocks: [DocumentBlock]
}

struct SpreadsheetCell: Identifiable, Codable, Hashable {
    var id: String { address }
    var address: String
    var rawValue: String
}

struct SpreadsheetSheet: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var rowCount: Int
    var columnCount: Int
    var cells: [SpreadsheetCell]
}

struct SpreadsheetFile: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var sheets: [SpreadsheetSheet]
}

struct SlidePage: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var body: String
    var layout: SlideLayout
}

struct PresentationFile: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var themeName: String
    var slides: [SlidePage]
}

struct WorkspaceFile: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var fileType: WorkspaceFileType
    var parentFolderId: String?
    var createdAt: Date
    var updatedAt: Date
    var starred: Bool
    var trashed: Bool
    var shared: Bool
    var ownerName: String
    var accessRole: AccessRole
    var sizeDescription: String
    var permissions: [FilePermission]
    var linkSettings: SharedLinkSettings
    var comments: [FileComment]
    var lastOpenedAt: Date?
}

struct WorkspaceData: Codable, Hashable {
    var rootFolderId: String
    var folders: [WorkspaceFolder]
    var files: [WorkspaceFile]
    var documents: [DocumentFile]
    var spreadsheets: [SpreadsheetFile]
    var presentations: [PresentationFile]
    var recentActivity: [RecentActivity]
    var profile: UserWorkspaceProfile
    var contacts: [WorkspaceContact] = []
}

struct WorkspaceSnapshotPayload: Codable, Hashable {
    var metadata: WorkspaceSnapshotMetadata
    var data: WorkspaceData
}

struct PendingHandoff: Codable, Hashable {
    var fileId: String
    var fileType: WorkspaceFileType
    var sourceApp: String
    var targetApp: String
    var createdAt: Date
}

struct PersistedWorkspaceEnvelope: Codable, Hashable {
    var selectedSourceType: WorkspaceSourceType
    var seededData: WorkspaceData
    var bundledSnapshotData: WorkspaceData?
    var bundledSnapshotMetadata: WorkspaceSnapshotMetadata?
    var importedSnapshotData: WorkspaceData?
    var importedSnapshotMetadata: WorkspaceSnapshotMetadata?
    var importedSnapshotFilename: String?
    var lastHandoff: PendingHandoff?
}

struct EditorRoute: Identifiable, Hashable {
    var fileId: String

    var id: String { fileId }
}

struct AppAlert: Identifiable, Hashable {
    var id: String
    var title: String
    var message: String
}

enum BrowserItem: Identifiable, Hashable {
    case folder(WorkspaceFolder)
    case file(WorkspaceFile)

    var id: String {
        switch self {
        case .folder(let folder):
            return folder.id
        case .file(let file):
            return file.id
        }
    }
}

extension WorkspaceFile {
    var commentCount: Int {
        comments.count
    }
}
