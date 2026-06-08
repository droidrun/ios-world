import Foundation

enum AccessibilityID {
    static let profileResetAppState = "profile_reset_app_state"
    static let debugSwitchSnapshotMode = "debug_switch_snapshot_mode"

    static let fileActionOpenInDocs = "file_action_open_in_docs"
    static let fileActionOpenInSheets = "file_action_open_in_sheets"
    static let fileActionOpenInSlides = "file_action_open_in_slides"
    static let fileActionRename = "file_action_rename"
    static let fileActionMove = "file_action_move"
    static let fileActionDuplicate = "file_action_duplicate"
    static let fileActionStar = "file_action_star"
    static let fileActionTrash = "file_action_trash"
    static let fileActionRestore = "file_action_restore"

    static let docsEditorTitleField = "docs_editor_title_field"
    static let docsEditorBody = "docs_editor_body"
    static let docsToolbarBold = "docs_toolbar_bold"
    static let docsToolbarItalic = "docs_toolbar_italic"
    static let docsToolbarUnderline = "docs_toolbar_underline"
    static let docsToolbarBullets = "docs_toolbar_bullets"
    static let docsToolbarHeading = "docs_toolbar_heading"

    static let sheetsTitleField = "sheets_title_field"
    static let sheetFormulaBar = "sheet_formula_bar"
    static let sheetAddRowButton = "sheet_add_row_button"
    static let sheetAddColumnButton = "sheet_add_column_button"

    static let slidesEditButton = "slides_edit_button"
    static let slidesTitleField = "slides_title_field"
    static let slidesAddSlideButton = "slides_add_slide_button"
    static let slidesDuplicateSlideButton = "slides_duplicate_slide_button"
    static let slidesDeleteSlideButton = "slides_delete_slide_button"
    static let slidesSlideTitleField = "slides_slide_title_field"
    static let slidesSlideBodyField = "slides_slide_body_field"

    static func sourceBadge(_ sourceType: WorkspaceSourceType) -> String {
        "source_badge_\(sourceType.rawValue)"
    }

    static func folderRow(_ name: String) -> String {
        "folder_row_\(name.stableSlug)"
    }

    static func fileRow(_ file: WorkspaceFile) -> String {
        "file_row_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
    }

    static func fileDetail(_ file: WorkspaceFile) -> String {
        "file_detail_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
    }

    static func recentRow(_ file: WorkspaceFile) -> String {
        "recent_row_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
    }

    static func sharedRow(_ file: WorkspaceFile) -> String {
        "shared_row_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
    }

    static func starredRow(_ file: WorkspaceFile) -> String {
        "starred_row_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
    }

    static func trashRow(_ file: WorkspaceFile) -> String {
        "trash_row_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
    }

    static func searchResultRow(_ item: BrowserItem) -> String {
        switch item {
        case .folder(let folder):
            return "search_folder_\(folder.name.stableSlug)"
        case .file(let file):
            return "search_file_\(file.fileType.accessibilityPrefix)_\(file.name.stableSlug)"
        }
    }

    static func activityRow(_ activity: RecentActivity) -> String {
        "activity_row_\(activity.id)"
    }

    static func permissionRow(_ permission: FilePermission) -> String {
        "permission_row_\(permission.personName.stableSlug)"
    }

    static func emptyState(_ name: String) -> String {
        "empty_state_\(name.stableSlug)"
    }

    static func metadataLabel(_ name: String) -> String {
        "metadata_label_\(name.stableSlug)"
    }

    static func sheetCell(_ address: String) -> String {
        "sheet_cell_\(address)"
    }

    static func sheetTab(_ index: Int) -> String {
        "sheet_tab_\(index)"
    }

    static func slidesThumbnail(_ index: Int) -> String {
        "slides_thumbnail_\(index)"
    }
}
