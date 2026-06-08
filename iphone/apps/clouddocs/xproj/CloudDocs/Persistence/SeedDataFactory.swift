import Foundation

enum SeedDataFactory {
    static let refreshedProfileEmail = "jordan.avery@email.com"

    static let seededContacts: [WorkspaceContact] = [
        WorkspaceContact(id: "contact_jordan_lee", name: "Jordan Lee", email: "jordan.lee@email.com"),
        WorkspaceContact(id: "contact_sam_lee", name: "Sam Lee", email: "sam.lee@email.com"),
        WorkspaceContact(id: "contact_mina_shah", name: "Mina Shah", email: "mina.shah@email.com"),
        WorkspaceContact(id: "contact_riley_brooks", name: "Riley Brooks", email: "riley.brooks@email.com"),
        WorkspaceContact(id: "contact_jordan_park", name: "Jordan Park", email: "jordan.park@email.com"),
        WorkspaceContact(id: "contact_qa_team", name: "Device QA Team", email: "qa-team@email.com"),
        WorkspaceContact(id: "contact_infra", name: "Infra Admins", email: "infra@email.com"),
        WorkspaceContact(id: "contact_studio", name: "Studio Planning", email: "studio@email.com"),
    ]

    static func makeSeededData() -> WorkspaceData {
        let rootId = "folder_root_my_drive"
        let folders = makeFolders(rootId: rootId)
        let files = makeFiles()
        let documents = makeDocuments()
        let spreadsheets = makeSpreadsheets()
        let presentations = makePresentations()
        let activity = makeRecentActivity()

        return WorkspaceData(
            rootFolderId: rootId,
            folders: folders,
            files: files,
            documents: documents,
            spreadsheets: spreadsheets,
            presentations: presentations,
            recentActivity: activity,
            profile: UserWorkspaceProfile(
                id: "profile_jordan_avery",
                displayName: "Jordan Avery",
                email: refreshedProfileEmail,
                storageUsedGB: 42.8,
                storageLimitGB: 100
            ),
            contacts: seededContacts
        )
    }

    static func requiresRefresh(_ data: WorkspaceData) -> Bool {
        data.profile.email != refreshedProfileEmail
            || data.files.contains(where: { $0.name == "Meeting Notes" })
            || !data.files.contains(where: { $0.name == "Mobile Launch Plan" })
    }

    // MARK: - Folders (28 total)

    private static func makeFolders(rootId: String) -> [WorkspaceFolder] {
        [
            // 10 common folders from slides-sim/docs-sim
            folder(rootId, "My Drive", nil, updated: "2026-03-05T09:30:00Z"),
            folder("folder_projects", "Projects", rootId, updated: "2026-03-05T09:10:00Z", starred: true),
            folder("folder_research", "Research", rootId, updated: "2026-03-03T16:05:00Z"),
            folder("folder_personal", "Personal", rootId, updated: "2026-02-14T12:20:00Z"),
            folder("folder_shared_assets", "Shared Assets", rootId, updated: "2026-03-02T08:40:00Z", shared: true),
            folder("folder_archive", "Archive", rootId, updated: "2025-12-28T10:15:00Z"),
            folder("folder_q2_launch", "Q2 Launch", "folder_projects", updated: "2026-03-04T13:00:00Z"),
            folder("folder_user_interviews", "User Interviews", "folder_research", updated: "2026-02-26T18:30:00Z"),
            folder("folder_brand_kit", "Brand Kit", "folder_shared_assets", updated: "2026-01-20T14:00:00Z", shared: true),
            folder("folder_archive_2024", "2024", "folder_archive", updated: "2025-11-22T07:45:00Z"),

            // 18 unique folders from drive-sim
            folder("folder_design_sprint", "Design Sprint", rootId, updated: "2026-03-05T09:10:00Z"),
            folder("folder_product_strategy", "Product Strategy", rootId, updated: "2026-03-03T16:05:00Z"),
            folder("folder_research_ops", "Research Ops", rootId, updated: "2026-03-01T14:20:00Z"),
            folder("folder_finance", "Finance", rootId, updated: "2026-02-18T11:10:00Z"),
            folder("folder_ops_review", "Ops Review", rootId, updated: "2026-03-02T09:35:00Z"),
            folder("folder_recruiting", "Recruiting", rootId, updated: "2026-02-24T14:40:00Z"),
            folder("folder_launch_prep", "Launch Prep", "folder_design_sprint", updated: "2026-03-04T13:00:00Z"),
            folder("folder_interview_synthesis", "Interview Synthesis", "folder_research_ops", updated: "2026-02-28T17:25:00Z"),
            folder("folder_brand_library", "Brand Library", "folder_shared_assets", updated: "2026-02-21T15:45:00Z", shared: true),
            folder("folder_budget_reviews", "Budget Reviews", "folder_finance", updated: "2026-02-26T15:15:00Z"),
            folder("folder_onsite_logistics", "Onsite Logistics", "folder_shared_assets", updated: "2026-02-19T11:00:00Z", shared: true),
            folder("folder_interview_debriefs", "Interview Debriefs", "folder_recruiting", updated: "2026-02-23T17:10:00Z"),
            folder("drive_design_ops", "Design Ops", nil, updated: "2026-03-05T07:50:00Z", shared: true, ownerName: "Northstar Design"),
            folder("drive_field_marketing", "Field Marketing", nil, updated: "2026-03-04T18:40:00Z", shared: true, ownerName: "Go-to-Market Team"),
            folder("drive_customer_success", "Customer Success", nil, updated: "2026-03-03T12:15:00Z", shared: true, ownerName: "Customer Success Team"),
            folder("folder_design_ops_templates", "Templates", "drive_design_ops", updated: "2026-03-05T07:40:00Z", shared: true, ownerName: "Northstar Design"),
            folder("folder_field_events", "Field Events", "drive_field_marketing", updated: "2026-03-04T18:20:00Z", shared: true, ownerName: "Go-to-Market Team"),
            folder("folder_success_playbooks", "Playbooks", "drive_customer_success", updated: "2026-03-03T12:05:00Z", shared: true, ownerName: "Customer Success Team")
        ]
    }

    // MARK: - Files (56 total: 20 docs + 17 sheets + 19 presentations)

    private static func makeFiles() -> [WorkspaceFile] {
        [
            // --- Documents (20 total) ---

            // 6 shared document IDs with docs-sim names and attributes
            file(
                id: "file_doc_meeting_notes",
                name: "Mobile Launch Plan",
                type: .document,
                parent: "folder_projects",
                created: "2026-01-08T10:00:00Z",
                updated: "2026-03-05T10:20:00Z",
                starred: true,
                shared: true,
                size: "68 KB",
                permissions: permissions(["Jordan Avery", "Device QA Team"], role: .editor),
                comments: [
                    comment("comment_meeting_1", "Mina Shah", "Add a short section covering pre-launch validation.", "2026-03-05T10:10:00Z")
                ],
                lastOpened: "2026-03-05T10:20:00Z"
            ),
            file(
                id: "file_doc_project_plan",
                name: "Compute Access Runbook",
                type: .document,
                parent: "folder_q2_launch",
                created: "2025-12-15T09:00:00Z",
                updated: "2026-03-05T09:35:00Z",
                starred: true,
                shared: true,
                size: "112 KB",
                permissions: permissions(["Jordan Avery", "Infra Admins"], role: .editor),
                comments: [
                    comment("comment_plan_1", "Riley Brooks", "Keep the account setup steps grouped together.", "2026-03-05T09:10:00Z")
                ],
                lastOpened: "2026-03-05T09:35:00Z"
            ),
            file(
                id: "file_doc_weekly_update",
                name: "Agent Systems Review",
                type: .document,
                parent: "folder_projects",
                created: "2026-02-01T08:30:00Z",
                updated: "2026-03-04T16:15:00Z",
                starred: true,
                shared: true,
                size: "54 KB",
                permissions: permissions(["Jordan Avery", "Sam Lee"], role: .viewer),
                comments: [
                    comment("comment_update_1", "Sam Lee", "Surface the evaluation highlights near the top.", "2026-03-04T15:50:00Z")
                ],
                lastOpened: "2026-03-04T16:15:00Z"
            ),
            file(
                id: "file_doc_research_outline",
                name: "Planning Notes 2.0",
                type: .document,
                parent: "folder_user_interviews",
                created: "2026-01-18T13:40:00Z",
                updated: "2026-03-03T13:05:00Z",
                shared: true,
                size: "76 KB",
                permissions: permissions(["Jordan Avery", "Jordan Park"], role: .editor),
                comments: [
                    comment("comment_research_1", "Jordan Park", "Leave the attendee list pinned near the top.", "2026-03-03T12:55:00Z")
                ],
                lastOpened: "2026-03-03T13:05:00Z"
            ),
            file(
                id: "file_doc_hiring_notes",
                name: "Content Queue",
                type: .document,
                parent: "folder_personal",
                created: "2025-12-02T09:15:00Z",
                updated: "2026-03-02T11:50:00Z",
                shared: true,
                size: "39 KB",
                permissions: permissions(["Jordan Avery", "Studio Planning"], role: .editor),
                comments: [
                    comment("comment_hiring_1", "Jordan Avery", "Keep this aligned with the next publishing batch.", "2026-03-02T11:40:00Z")
                ],
                lastOpened: "2026-03-02T11:50:00Z"
            ),
            file(
                id: "file_doc_travel_checklist",
                name: "Untitled document",
                type: .document,
                parent: "folder_personal",
                created: "2026-01-28T06:30:00Z",
                updated: "2026-03-01T18:10:00Z",
                shared: false,
                size: "27 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-01T18:10:00Z"
            ),

            // 2 unique documents from docs-sim
            file(
                id: "file_doc_todo_capture",
                name: "Untitled document",
                type: .document,
                parent: "folder_projects",
                created: "2026-02-20T08:00:00Z",
                updated: "2026-02-28T17:40:00Z",
                shared: false,
                size: "31 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-28T17:40:00Z"
            ),
            file(
                id: "file_doc_research_invite",
                name: "Untitled document",
                type: .document,
                parent: "folder_personal",
                created: "2026-02-18T09:30:00Z",
                updated: "2026-02-27T09:20:00Z",
                shared: false,
                size: "24 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-27T09:20:00Z"
            ),

            // 11 unique documents from drive-sim
            file(
                id: "file_doc_q3_planning_brief",
                name: "Q3 Planning Brief",
                type: .document,
                parent: "folder_product_strategy",
                created: "2026-01-05T10:00:00Z",
                updated: "2026-03-04T18:10:00Z",
                starred: true,
                shared: true,
                size: "96 KB",
                permissions: permissions(["Jordan Avery", "Jordan Kim"], role: .editor),
                comments: [
                    comment("comment_q3_brief_1", "Jordan Kim", "The staffing assumptions section looks good. Let's tighten the timeline on page two.", "2026-03-04T17:20:00Z")
                ],
                lastOpened: "2026-03-05T08:30:00Z"
            ),
            file(
                id: "file_doc_sprint_retro",
                name: "Sprint Retro Notes",
                type: .document,
                parent: "folder_design_sprint",
                created: "2026-02-09T09:00:00Z",
                updated: "2026-03-03T15:45:00Z",
                starred: true,
                shared: false,
                size: "54 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [
                    comment("comment_sprint_retro_1", "Jordan Avery", "Capture one more action item around design review handoff.", "2026-03-03T15:10:00Z")
                ],
                lastOpened: "2026-03-04T09:45:00Z"
            ),
            file(
                id: "file_doc_interview_themes",
                name: "Customer Interview Themes",
                type: .document,
                parent: "folder_interview_synthesis",
                created: "2026-02-14T11:30:00Z",
                updated: "2026-02-28T18:20:00Z",
                shared: true,
                size: "84 KB",
                permissions: permissions(["Maya Patel", "Jordan Avery"], role: .commenter),
                comments: [
                    comment("comment_interview_themes_1", "Maya Patel", "Please merge the onboarding pain points into one section before sharing wider.", "2026-02-28T17:45:00Z")
                ],
                lastOpened: "2026-03-01T10:15:00Z",
                ownerName: "Maya Patel"
            ),
            file(
                id: "file_doc_vendor_checklist",
                name: "Vendor Checklist",
                type: .document,
                parent: "folder_shared_assets",
                created: "2026-02-05T14:00:00Z",
                updated: "2026-02-27T12:10:00Z",
                shared: true,
                size: "42 KB",
                permissions: permissions(["Operations Team", "Jordan Avery"], role: .viewer),
                comments: [
                    comment("comment_vendor_checklist_1", "Operations Team", "Security review is complete. Procurement is the only open item.", "2026-02-27T11:00:00Z")
                ],
                lastOpened: "2026-02-27T15:30:00Z",
                ownerName: "Operations Team"
            ),
            file(
                id: "file_doc_weekend_itinerary",
                name: "Weekend Itinerary",
                type: .document,
                parent: "folder_personal",
                created: "2026-02-08T08:00:00Z",
                updated: "2026-02-11T18:40:00Z",
                size: "19 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-11T18:45:00Z"
            ),
            file(
                id: "file_doc_partner_brief",
                name: "Partner Brief",
                type: .document,
                parent: "folder_shared_assets",
                created: "2026-02-12T09:20:00Z",
                updated: "2026-03-02T14:05:00Z",
                shared: true,
                size: "71 KB",
                permissions: permissions(["Alex Moreno", "Jordan Avery", "Go-to-Market Team"], role: .commenter),
                comments: [
                    comment("comment_partner_brief_1", "Alex Moreno", "Please tighten the rollout section before we share it externally.", "2026-03-02T13:50:00Z")
                ],
                lastOpened: "2026-03-02T14:15:00Z",
                ownerName: "Alex Moreno"
            ),
            file(
                id: "file_doc_quarterly_goals",
                name: "Quarterly Goals",
                type: .document,
                parent: "folder_ops_review",
                created: "2026-01-11T08:40:00Z",
                updated: "2026-03-02T10:10:00Z",
                starred: true,
                shared: true,
                size: "63 KB",
                permissions: permissions(["Jordan Avery", "Leadership Team"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-02T10:30:00Z"
            ),
            file(
                id: "file_doc_hiring_funnel_notes",
                name: "Hiring Funnel Notes",
                type: .document,
                parent: "folder_interview_debriefs",
                created: "2026-02-16T15:00:00Z",
                updated: "2026-02-24T18:45:00Z",
                shared: true,
                size: "47 KB",
                permissions: permissions(["Priya Shah", "Jordan Avery"], role: .commenter),
                comments: [
                    comment("comment_hiring_funnel_1", "Priya Shah", "Keep candidate names out of the summary version.", "2026-02-24T18:20:00Z")
                ],
                lastOpened: "2026-02-24T18:50:00Z",
                ownerName: "Priya Shah"
            ),
            file(
                id: "file_doc_client_workshop_agenda",
                name: "Client Workshop Agenda",
                type: .document,
                parent: "folder_design_ops_templates",
                created: "2026-02-20T10:30:00Z",
                updated: "2026-03-05T07:35:00Z",
                shared: true,
                size: "58 KB",
                permissions: permissions(["Northstar Design", "Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T07:36:00Z",
                ownerName: "Northstar Design"
            ),
            file(
                id: "file_doc_playbook_notes",
                name: "Playbook Notes",
                type: .document,
                parent: "folder_success_playbooks",
                created: "2026-02-22T11:10:00Z",
                updated: "2026-03-03T11:55:00Z",
                shared: true,
                size: "66 KB",
                permissions: permissions(["Customer Success Team", "Jordan Avery"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-03T12:00:00Z",
                ownerName: "Customer Success Team"
            ),
            file(
                id: "file_doc_archive_notes",
                name: "Archive Notes",
                type: .document,
                parent: "folder_archive",
                created: "2025-12-12T08:00:00Z",
                updated: "2026-01-12T10:00:00Z",
                trashed: true,
                size: "23 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-01-12T10:20:00Z"
            ),

            file(
                id: "file_doc_budget_tracker",
                name: "Budget Tracker",
                type: .document,
                parent: "folder_projects",
                created: "2025-12-19T08:00:00Z",
                updated: "2026-03-02T16:25:00Z",
                shared: true,
                size: "31 KB",
                permissions: permissions(["Jordan Avery", "Finance Ops"], role: .editor),
                comments: [],
                lastOpened: "2026-03-02T16:20:00Z"
            ),

            // --- Spreadsheets (17 total) ---

            // 4 shared spreadsheet IDs
            file(
                id: "file_sheet_budget_tracker",
                name: "Budget Tracker",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2025-12-19T08:00:00Z",
                updated: "2026-03-02T16:25:00Z",
                shared: true,
                size: "94 KB",
                permissions: permissions(["Jordan Avery", "Finance Ops"], role: .editor),
                comments: [],
                lastOpened: "2026-03-02T16:20:00Z"
            ),
            file(
                id: "file_sheet_experiment_results",
                name: "2026 Open House Volunteers",
                type: .spreadsheet,
                parent: "folder_research",
                created: "2026-02-18T15:00:00Z",
                updated: "2026-03-04T16:15:00Z",
                starred: true,
                shared: true,
                size: "82 KB",
                permissions: permissions(["Jordan Avery", "Research Group"], role: .commenter),
                comments: [
                    comment("comment_sheet_results_1", "Research Group", "Please keep the baseline data frozen.", "2026-02-26T09:20:00Z")
                ],
                lastOpened: "2026-03-04T16:15:00Z"
            ),
            file(
                id: "file_sheet_task_tracker",
                name: "Device Testing Tasks",
                type: .spreadsheet,
                parent: "folder_q2_launch",
                created: "2026-02-28T11:10:00Z",
                updated: "2026-03-06T15:12:00Z",
                shared: true,
                size: "73 KB",
                permissions: permissions(["Jordan Avery", "QA Lead", "Product Lead"], role: .editor),
                comments: [],
                lastOpened: "2026-03-06T15:12:00Z"
            ),
            file(
                id: "file_sheet_event_planning",
                name: "League Operations Master",
                type: .spreadsheet,
                parent: "folder_shared_assets",
                created: "2026-01-31T17:00:00Z",
                updated: "2026-03-03T09:40:00Z",
                shared: true,
                trashed: false,
                size: "58 KB",
                permissions: permissions(["Jordan Avery", "Operations Group"], role: .editor),
                comments: [],
                lastOpened: "2026-03-03T09:40:00Z"
            ),

            // 6 unique spreadsheets from sheets-sim
            file(
                id: "file_sheet_ml_tea",
                name: "ML Reading Group AY25-26",
                type: .spreadsheet,
                parent: "folder_shared_assets",
                created: "2026-02-10T09:15:00Z",
                updated: "2026-02-26T13:05:00Z",
                shared: true,
                size: "49 KB",
                permissions: permissions(["Jordan Avery", "Study Group"], role: .editor),
                comments: [],
                lastOpened: "2026-02-26T13:05:00Z"
            ),
            file(
                id: "file_sheet_untitled",
                name: "Untitled spreadsheet",
                type: .spreadsheet,
                parent: "folder_personal",
                created: "2026-02-23T09:00:00Z",
                updated: "2026-02-23T09:00:00Z",
                shared: false,
                size: "18 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-23T09:00:00Z"
            ),
            file(
                id: "file_sheet_planning_sync_0218",
                name: "Planning Sync - 2026/02/18 14:30",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2026-02-18T14:30:00Z",
                updated: "2026-02-18T14:30:00Z",
                shared: true,
                size: "36 KB",
                permissions: permissions(["Jordan Avery", "Product Lead", "QA Lead"], role: .editor),
                comments: [],
                lastOpened: "2026-02-18T14:30:00Z"
            ),
            file(
                id: "file_sheet_phd_director",
                name: "Imported Committee Notes.xlsx",
                type: .spreadsheet,
                parent: "folder_research",
                created: "2026-02-17T12:00:00Z",
                updated: "2026-02-17T12:00:00Z",
                shared: true,
                size: "41 KB",
                permissions: permissions(["Jordan Avery", "Committee Chair"], role: .viewer),
                comments: [],
                lastOpened: "2026-02-17T12:00:00Z"
            ),
            file(
                id: "file_sheet_partner_sync_0214",
                name: "Partner Sync - 2026/02/14 15:00",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2026-02-14T15:00:00Z",
                updated: "2026-02-14T15:00:00Z",
                shared: true,
                size: "34 KB",
                permissions: permissions(["Jordan Avery", "QA Lead", "Product Lead"], role: .editor),
                comments: [],
                lastOpened: "2026-02-14T15:00:00Z"
            ),
            file(
                id: "file_sheet_launch_planning_0213",
                name: "Launch Planning - 2026/02/13 13:00",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2026-02-13T13:00:00Z",
                updated: "2026-02-13T13:00:00Z",
                shared: true,
                size: "33 KB",
                permissions: permissions(["Jordan Avery", "QA Lead", "Product Lead"], role: .editor),
                comments: [],
                lastOpened: "2026-02-13T13:00:00Z"
            ),

            // 7 unique spreadsheets from drive-sim
            file(
                id: "file_sheet_launch_tracker",
                name: "Launch Tracker",
                type: .spreadsheet,
                parent: "folder_launch_prep",
                created: "2026-01-22T12:20:00Z",
                updated: "2026-03-05T08:20:00Z",
                shared: true,
                size: "74 KB",
                permissions: permissions(["Product Ops", "Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T08:25:00Z",
                ownerName: "Product Ops"
            ),
            file(
                id: "file_sheet_headcount_plan",
                name: "Headcount Plan",
                type: .spreadsheet,
                parent: "folder_finance",
                created: "2026-01-18T13:20:00Z",
                updated: "2026-02-25T12:10:00Z",
                shared: true,
                size: "61 KB",
                permissions: permissions(["Finance Team", "Jordan Avery"], role: .viewer),
                comments: [],
                lastOpened: "2026-02-25T13:00:00Z",
                ownerName: "Finance Team"
            ),
            file(
                id: "file_sheet_interview_roster",
                name: "Interview Roster",
                type: .spreadsheet,
                parent: "folder_research_ops",
                created: "2026-02-01T10:15:00Z",
                updated: "2026-02-20T09:30:00Z",
                size: "36 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-20T09:35:00Z"
            ),
            file(
                id: "file_sheet_expense_rollup",
                name: "Expense Rollup",
                type: .spreadsheet,
                parent: "folder_finance",
                created: "2026-02-02T10:00:00Z",
                updated: "2026-02-14T16:20:00Z",
                size: "29 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-14T16:30:00Z"
            ),
            file(
                id: "file_sheet_budget_review",
                name: "Budget Review",
                type: .spreadsheet,
                parent: "folder_budget_reviews",
                created: "2026-02-06T09:50:00Z",
                updated: "2026-02-26T15:25:00Z",
                shared: true,
                size: "44 KB",
                permissions: permissions(["Finance Team", "Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-26T15:40:00Z",
                ownerName: "Finance Team"
            ),
            file(
                id: "file_sheet_event_run_of_show",
                name: "Event Run of Show",
                type: .spreadsheet,
                parent: "folder_field_events",
                created: "2026-02-18T08:30:00Z",
                updated: "2026-03-04T18:05:00Z",
                shared: true,
                size: "52 KB",
                permissions: permissions(["Go-to-Market Team", "Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-04T18:08:00Z",
                ownerName: "Go-to-Market Team"
            ),
            file(
                id: "file_sheet_support_escalations",
                name: "Support Escalation Tracker",
                type: .spreadsheet,
                parent: "folder_success_playbooks",
                created: "2026-02-21T13:00:00Z",
                updated: "2026-03-03T12:00:00Z",
                shared: true,
                size: "39 KB",
                permissions: permissions(["Customer Success Team", "Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-03T12:01:00Z",
                ownerName: "Customer Success Team"
            ),

            // --- Presentations (19 total) ---

            // 9 unique from slides-sim
            file(
                id: "file_slides_speaking_skills",
                name: "Conference Practice Deck",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-02-17T20:10:00Z",
                updated: "2026-03-05T06:40:00Z",
                starred: true,
                shared: true,
                size: "7.8 MB",
                permissions: permissions(["Jordan Avery", "Speaker Series"], role: .editor),
                comments: [
                    comment("comment_speaking_skills_1", "Riley Park", "Can we tighten slide three before the talk?", "2026-03-05T05:55:00Z"),
                    comment("comment_speaking_skills_2", "Morgan Diaz", "The intro slide is ready for rehearsal screenshots.", "2026-03-04T21:15:00Z")
                ],
                lastOpened: "2026-03-05T06:40:00Z"
            ),
            file(
                id: "file_slides_superintelligence",
                name: "[Draft] Autonomous Agents",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-02-19T14:20:00Z",
                updated: "2026-02-19T16:55:00Z",
                shared: true,
                size: "3.1 MB",
                permissions: permissions(["Jordan Avery", "Riley Park"], role: .editor),
                comments: [
                    comment("comment_autonomous_agents_1", "Riley Park", "Keep the scope narrow for the project framing.", "2026-02-19T16:10:00Z")
                ],
                lastOpened: "2026-02-19T16:55:00Z"
            ),
            file(
                id: "file_slides_frontend_codegen",
                name: "Frontend Codegen Review",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-02-28T11:40:00Z",
                updated: "2026-03-01T09:20:00Z",
                size: "2.4 MB",
                permissions: permissions(["Jordan Avery", "Design Systems"], role: .editor),
                comments: [
                    comment("comment_codegen_1", "Design Systems", "Please include one high-fidelity failure case.", "2026-03-01T08:40:00Z")
                ],
                lastOpened: "2026-03-01T09:20:00Z"
            ),
            file(
                id: "file_slides_life_pittsburgh_s26",
                name: "S26 City Guide",
                type: .presentation,
                parent: "folder_brand_kit",
                created: "2026-02-01T08:10:00Z",
                updated: "2026-02-18T13:00:00Z",
                shared: true,
                size: "5.1 MB",
                permissions: permissions(["Jordan Avery", "City Guide Club"], role: .viewer),
                comments: [],
                lastOpened: "2026-02-18T13:00:00Z"
            ),
            file(
                id: "file_slides_life_pittsburgh_s25",
                name: "S25 City Guide",
                type: .presentation,
                parent: "folder_brand_kit",
                created: "2025-12-29T12:10:00Z",
                updated: "2026-01-14T18:45:00Z",
                shared: true,
                size: "4.6 MB",
                permissions: permissions(["Jordan Avery", "City Guide Club"], role: .viewer),
                comments: [],
                lastOpened: "2026-01-14T18:45:00Z"
            ),
            file(
                id: "file_slides_healthcare_startup",
                name: "Healthcare Startup Criteria",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-01-12T10:40:00Z",
                updated: "2026-02-11T21:00:00Z",
                shared: true,
                size: "2.9 MB",
                permissions: permissions(["Jordan Avery", "Riley Park"], role: .editor),
                comments: [
                    comment("comment_healthcare_1", "Riley Park", "The criteria slide feels strong for partner review.", "2026-02-11T20:20:00Z")
                ],
                lastOpened: "2026-02-11T21:00:00Z"
            ),
            file(
                id: "file_slides_temperature_check",
                name: "Signal Check",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-01-04T09:25:00Z",
                updated: "2026-01-26T17:10:00Z",
                size: "1.8 MB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-01-26T17:10:00Z"
            ),
            file(
                id: "file_slides_cohere_talk",
                name: "Agent Systems Talk",
                type: .presentation,
                parent: "folder_research",
                created: "2026-01-17T15:20:00Z",
                updated: "2026-01-24T20:25:00Z",
                size: "3.2 MB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-01-24T20:25:00Z"
            ),
            file(
                id: "file_slides_athena_pitch",
                name: "Product Pitch",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-01-22T13:05:00Z",
                updated: "2026-01-23T19:10:00Z",
                size: "2.5 MB",
                permissions: permissions(["Jordan Avery", "Pilot Team"], role: .editor),
                comments: [],
                lastOpened: "2026-01-23T19:10:00Z"
            ),

            // 1 shared presentation
            file(
                id: "file_slides_quarterly_review",
                name: "Quarterly Review",
                type: .presentation,
                parent: "folder_archive_2024",
                created: "2025-10-02T08:00:00Z",
                updated: "2025-11-20T14:20:00Z",
                trashed: true,
                size: "4.1 MB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2025-11-20T14:20:00Z"
            ),

            // 3 unique presentations from docs-sim/sheets-sim
            file(
                id: "file_slides_team_update",
                name: "Team Update",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-01-04T07:45:00Z",
                updated: "2026-03-05T06:40:00Z",
                starred: true,
                shared: true,
                size: "3.6 MB",
                permissions: permissions(["Jordan Avery", "Executive Review"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-05T06:40:00Z"
            ),
            file(
                id: "file_slides_project_pitch",
                name: "Project Pitch",
                type: .presentation,
                parent: "folder_q2_launch",
                created: "2026-01-10T15:20:00Z",
                updated: "2026-02-23T11:55:00Z",
                shared: true,
                size: "2.8 MB",
                permissions: permissions(["Jordan Avery", "Morgan Lee"], role: .editor),
                comments: [],
                lastOpened: "2026-02-23T11:55:00Z"
            ),
            file(
                id: "file_slides_workshop_slides",
                name: "Workshop Slides",
                type: .presentation,
                parent: "folder_brand_kit",
                created: "2026-01-08T12:20:00Z",
                updated: "2026-01-30T17:35:00Z",
                shared: false,
                size: "2.2 MB",
                permissions: permissions(["Jordan Avery", "Brand Library"], role: .viewer),
                comments: [],
                lastOpened: "2026-01-30T17:35:00Z"
            ),

            // 6 unique presentations from drive-sim
            file(
                id: "file_slides_all_hands_story",
                name: "All Hands Storyline",
                type: .presentation,
                parent: "folder_product_strategy",
                created: "2026-01-28T14:00:00Z",
                updated: "2026-03-05T07:10:00Z",
                starred: true,
                shared: true,
                size: "3.2 MB",
                permissions: permissions(["Jordan Avery", "Leadership Team"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-05T07:30:00Z"
            ),
            file(
                id: "file_slides_creative_review",
                name: "Creative Review",
                type: .presentation,
                parent: "folder_brand_library",
                created: "2026-02-08T11:00:00Z",
                updated: "2026-02-22T17:10:00Z",
                shared: true,
                size: "2.4 MB",
                permissions: permissions(["Design Team", "Jordan Avery"], role: .viewer),
                comments: [],
                lastOpened: "2026-02-22T17:20:00Z",
                ownerName: "Design Team"
            ),
            file(
                id: "file_slides_workshop_deck",
                name: "Workshop Deck",
                type: .presentation,
                parent: "folder_design_sprint",
                created: "2026-02-03T11:30:00Z",
                updated: "2026-02-17T13:45:00Z",
                size: "2.1 MB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-02-17T14:00:00Z"
            ),
            file(
                id: "file_slides_board_prep",
                name: "Board Prep",
                type: .presentation,
                parent: "folder_product_strategy",
                created: "2026-02-10T10:10:00Z",
                updated: "2026-03-01T16:30:00Z",
                starred: true,
                size: "4.0 MB",
                permissions: permissions(["Jordan Avery", "Leadership Team"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-01T17:00:00Z"
            ),
            file(
                id: "file_slides_partner_kickoff",
                name: "Partner Kickoff",
                type: .presentation,
                parent: "folder_field_events",
                created: "2026-02-25T09:15:00Z",
                updated: "2026-03-04T17:50:00Z",
                shared: true,
                size: "2.9 MB",
                permissions: permissions(["Go-to-Market Team", "Jordan Avery"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-04T17:55:00Z",
                ownerName: "Go-to-Market Team"
            ),
            file(
                id: "file_slides_design_system_update",
                name: "Design System Update",
                type: .presentation,
                parent: "drive_design_ops",
                created: "2026-02-19T11:45:00Z",
                updated: "2026-03-05T07:42:00Z",
                shared: true,
                size: "2.6 MB",
                permissions: permissions(["Northstar Design", "Jordan Avery"], role: .viewer),
                comments: [],
                lastOpened: "2026-03-05T07:43:00Z",
                ownerName: "Northstar Design"
            ),

            // ── Benchmark diversification: additional docs/sheets/decks ──────
            // Added so tasks that modify "Budget Tracker", "Mobile Launch Plan", etc.
            // can be spread across distinct documents instead of colliding.

            // Docs (alternatives to Mobile Launch Plan)
            file(
                id: "file_doc_q2_roadmap",
                name: "Q2 Roadmap",
                type: .document,
                parent: "folder_q2_launch",
                created: "2026-01-15T09:00:00Z",
                updated: "2026-03-05T11:00:00Z",
                shared: true,
                size: "46 KB",
                permissions: permissions(["Jordan Avery", "Product Team"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T11:00:00Z"
            ),
            file(
                id: "file_doc_launch_retro",
                name: "Launch Retrospective",
                type: .document,
                parent: "folder_projects",
                created: "2026-02-20T14:00:00Z",
                updated: "2026-03-04T17:00:00Z",
                shared: true,
                size: "38 KB",
                permissions: permissions(["Jordan Avery", "Engineering Team"], role: .editor),
                comments: [],
                lastOpened: "2026-03-04T17:00:00Z"
            ),
            file(
                id: "file_doc_feature_spec",
                name: "Feature Spec Draft",
                type: .document,
                parent: "folder_projects",
                created: "2026-02-27T10:00:00Z",
                updated: "2026-03-05T14:22:00Z",
                shared: true,
                size: "52 KB",
                permissions: permissions(["Jordan Avery", "Design", "Product Team"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T14:22:00Z"
            ),

            // Spreadsheets (alternatives to Budget Tracker + Device Testing Tasks)
            file(
                id: "file_sheet_monthly_expense",
                name: "Monthly Expense Log",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2025-11-10T09:00:00Z",
                updated: "2026-03-05T10:00:00Z",
                shared: false,
                size: "41 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T10:00:00Z"
            ),
            file(
                id: "file_sheet_subscription_audit",
                name: "Subscription Audit",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2026-01-22T18:30:00Z",
                updated: "2026-03-04T20:15:00Z",
                shared: false,
                size: "22 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-04T20:15:00Z"
            ),
            file(
                id: "file_sheet_travel_budget",
                name: "Travel Budget",
                type: .spreadsheet,
                parent: "folder_personal",
                created: "2026-02-12T19:00:00Z",
                updated: "2026-03-03T21:00:00Z",
                shared: false,
                size: "28 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-03T21:00:00Z"
            ),
            file(
                id: "file_sheet_spending_dashboard",
                name: "Spending Dashboard",
                type: .spreadsheet,
                parent: "folder_projects",
                created: "2025-12-01T08:00:00Z",
                updated: "2026-03-06T07:30:00Z",
                shared: false,
                size: "64 KB",
                permissions: permissions(["Jordan Avery"], role: .editor),
                comments: [],
                lastOpened: "2026-03-06T07:30:00Z"
            ),
            file(
                id: "file_sheet_bug_triage",
                name: "Bug Triage Log",
                type: .spreadsheet,
                parent: "folder_q2_launch",
                created: "2026-02-14T11:00:00Z",
                updated: "2026-03-06T16:30:00Z",
                shared: true,
                size: "49 KB",
                permissions: permissions(["Jordan Avery", "QA Lead"], role: .editor),
                comments: [],
                lastOpened: "2026-03-06T16:30:00Z"
            ),
            file(
                id: "file_sheet_qa_matrix",
                name: "QA Test Matrix",
                type: .spreadsheet,
                parent: "folder_q2_launch",
                created: "2026-02-06T14:00:00Z",
                updated: "2026-03-05T15:00:00Z",
                shared: true,
                size: "56 KB",
                permissions: permissions(["Jordan Avery", "QA Lead", "Product Lead"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T15:00:00Z"
            ),

            // Presentations (alternatives to Conference Practice Deck)
            file(
                id: "file_slides_product_demo",
                name: "Product Demo Deck",
                type: .presentation,
                parent: "folder_q2_launch",
                created: "2026-02-05T09:30:00Z",
                updated: "2026-03-05T08:45:00Z",
                shared: true,
                size: "3.4 MB",
                permissions: permissions(["Jordan Avery", "Product Team"], role: .editor),
                comments: [],
                lastOpened: "2026-03-05T08:45:00Z"
            ),
            file(
                id: "file_slides_all_hands_q2",
                name: "Q2 All-Hands",
                type: .presentation,
                parent: "folder_projects",
                created: "2026-02-18T13:00:00Z",
                updated: "2026-03-04T16:00:00Z",
                shared: true,
                size: "2.8 MB",
                permissions: permissions(["Jordan Avery", "Leadership Team"], role: .editor),
                comments: [],
                lastOpened: "2026-03-04T16:00:00Z"
            )
        ]
    }

    // MARK: - Documents (20 total)

    private static func makeDocuments() -> [DocumentFile] {
        [
            // 6 shared document IDs with docs-sim content
            document(
                id: "file_doc_meeting_notes",
                title: "Mobile Launch Plan",
                body: """
                Mobile launch plan

                Priorities
                - Verify onboarding flows across every app
                - Align default signed-in user profiles
                - Tighten image handling for preview-heavy screens
                - Run a final UI polish sweep before release

                March 5, 2026

                Meeting Notes:
                - The mail and messaging apps are stable in current testing
                - Weather and maps no longer show layout clipping on narrow devices
                - Final release package review is scheduled for Friday afternoon
                """
            ),
            document(
                id: "file_doc_project_plan",
                title: "Compute Access Runbook",
                body: """
                Shared compute access runbook

                Before requesting access, confirm the owner for the workload and list the tools that need to be pre-installed.

                1. Create the workspace account and set a recovery method.
                2. Verify command line access and MFA enrollment.
                3. Add the project details and storage request.
                4. Confirm the review queue and expected approval date.
                """
            ),
            document(
                id: "file_doc_weekly_update",
                title: "Agent Systems Review",
                body: """
                Site: https://northstar.example/agents/dashboard

                March 9, 2026

                Jordan Avery
                - Finalized the deployment workflow checklist
                - Started the desktop sandbox compatibility pass

                March 2, 2026
                Sam Lee
                - Landed the browser automation instrumentation update
                - Refreshed the model performance comparison table
                """
            ),
            document(
                id: "file_doc_research_outline",
                title: "Planning Notes 2.0",
                body: """
                February 6, 2026 | Planning sync v2.0
                Attendees: Jordan Avery | Jordan Park

                Meeting Notes:

                To-dos:
                - Confirm release scope
                - Review simulator parity issues
                - Publish the test plan summary
                """
            ),
            document(
                id: "file_doc_hiring_notes",
                title: "Content Queue",
                body: """
                February 5, 2026

                Editorial queue
                - Finalize newsletter draft
                - Prepare launch copy variants
                - Review illustration backlog for next week
                """
            ),
            document(
                id: "file_doc_travel_checklist",
                title: "Untitled document",
                body: """
                https://example.com/shared/research-pack
                """
            ),

            // 2 unique documents from docs-sim
            document(
                id: "file_doc_todo_capture",
                title: "Untitled document",
                body: """
                Follow-up note

                Thanks again for the meeting today.
                I wanted to send the project update, outline the remaining polish items, and confirm the next review window.
                """
            ),
            document(
                id: "file_doc_research_invite",
                title: "Untitled document",
                body: """
                Research study intake draft

                Participant intake notes
                - Confirm device type
                - Record time-on-task observations
                - Log follow-up questions
                """
            ),

            // 11 unique documents from drive-sim
            document(
                id: "file_doc_q3_planning_brief",
                title: "Q3 Planning Brief",
                body: """
                Q3 planning brief

                Goal
                Align the product, support, and design work needed for the next quarterly release.

                Focus areas
                Improve activation, reduce support volume, and tighten the launch checklist for new workspaces.
                """
            ),
            document(
                id: "file_doc_sprint_retro",
                title: "Sprint Retro Notes",
                body: """
                Sprint retro

                What worked
                Review requests landed faster and the launch board stayed up to date for the full sprint.

                What to improve
                Clarify ownership earlier and reduce duplicate review threads.
                """
            ),
            document(
                id: "file_doc_interview_themes",
                title: "Customer Interview Themes",
                body: """
                Interview themes

                Top patterns
                Users want clearer setup guidance, fewer status surfaces, and better visibility into shared work.

                Next step
                Convert the strongest signals into a small set of product opportunities.
                """
            ),
            document(
                id: "file_doc_vendor_checklist",
                title: "Vendor Checklist",
                body: """
                Vendor checklist

                Complete legal review
                Confirm procurement owner
                Verify invoice routing
                Attach security signoff
                """
            ),
            document(
                id: "file_doc_weekend_itinerary",
                title: "Weekend Itinerary",
                body: """
                Weekend itinerary

                Friday
                Dinner with friends and an early train home.

                Saturday
                Museum, brunch, and afternoon walk.
                """
            ),
            document(
                id: "file_doc_partner_brief",
                title: "Partner Brief",
                body: """
                Partner brief

                Objective
                Align launch timing, messaging, and success metrics for the next partner release.

                Open questions
                Finalize rollout windows and confirm support ownership before distribution.
                """
            ),
            document(
                id: "file_doc_quarterly_goals",
                title: "Quarterly Goals",
                body: """
                Quarterly goals

                1. Improve first-week activation.
                2. Reduce support escalations tied to onboarding.
                3. Tighten the release review process across design and product.
                """
            ),
            document(
                id: "file_doc_hiring_funnel_notes",
                title: "Hiring Funnel Notes",
                body: """
                Hiring funnel notes

                Recruiting is healthy for product design and support ops.
                Next step is to consolidate interview feedback into one hiring readout.
                """
            ),
            document(
                id: "file_doc_client_workshop_agenda",
                title: "Client Workshop Agenda",
                body: """
                Workshop agenda

                Introductions
                Current workflow review
                Breakout mapping
                Prioritization and next steps
                """
            ),
            document(
                id: "file_doc_playbook_notes",
                title: "Playbook Notes",
                body: """
                Playbook notes

                Capture the best escalation examples, expected response times, and recommended owner paths for new cases.
                """
            ),
            document(
                id: "file_doc_archive_notes",
                title: "Archive Notes",
                body: """
                Archive notes

                This file is kept only for reference after the planning process changed in January.
                """
            ),
            document(
                id: "file_doc_budget_tracker",
                title: "Budget Tracker",
                body: """
                Budget Tracker — March 2026

                Monthly Budget: $500

                Spending
                Groceries: $185
                Dining Out: $62
                Subscriptions: $45
                Transportation: $38
                Entertainment: $25

                Total Spent: $355
                Remaining: $145
                """
            ),

            // ── Benchmark diversification: additional doc bodies ──
            document(
                id: "file_doc_q2_roadmap",
                title: "Q2 Roadmap",
                body: """
                Q2 2026 Roadmap

                Objectives:
                - Ship v3 API migration to production
                - Launch mobile redesign (Android + iOS)
                - Reduce p95 latency to under 200ms
                - Close out onboarding funnel work

                Milestones:
                - April: API v3 beta rollout
                - May: Mobile redesign internal preview
                - June: Public launch and perf review

                Risks / Dependencies:
                - Backend team capacity during API migration
                - Design review bandwidth for mobile
                """
            ),
            document(
                id: "file_doc_launch_retro",
                title: "Launch Retrospective",
                body: """
                Launch Retrospective — March 2026

                What went well:
                - Staged rollout kept incidents low
                - On-call rotation held through weekend spike
                - Messaging handoffs between product and support worked

                What did not:
                - Feature flag cleanup took longer than expected
                - Discovery copy changed twice post-launch
                - Analytics dashboards were not ready on day 1

                Action items:
                - Create flag cleanup checklist tied to the launch gate
                - Lock copy two weeks before launch
                - Dashboards ship as part of the launch definition of done
                """
            ),
            document(
                id: "file_doc_feature_spec",
                title: "Feature Spec Draft",
                body: """
                Feature Spec — Personalized Discover

                Summary:
                A personalized discover surface that uses recent activity to surface relevant content.

                User stories:
                - As a returning user, I see picks that reflect what I already liked
                - As a new user, I see a warm default until I interact enough

                Open questions:
                - How do we handle users with zero recent activity?
                - What is the minimum set of signals for a personalized row?
                - How often do we refresh picks?

                Next steps:
                - Align with ML on signal inventory
                - Design mock of empty state and ranked state
                - Stub backend endpoint behind feature flag
                """
            )
        ]
    }

    // MARK: - Spreadsheets (17 total)

    private static func makeSpreadsheets() -> [SpreadsheetFile] {
        [
            // file_sheet_budget_tracker: monthly personal spending tracker
            SpreadsheetFile(
                id: "file_sheet_budget_tracker",
                title: "Budget Tracker",
                sheets: [
                    sheet(
                        id: "sheet_budget_tracker_march",
                        name: "March 2026",
                        rows: 12,
                        columns: 3,
                        values: [
                            "A1": "Category",
                            "B1": "Amount",
                            "A2": "Monthly Budget",
                            "B2": "500",
                            "A3": "",
                            "A4": "Spending",
                            "A5": "Groceries",
                            "B5": "185",
                            "A6": "Dining Out",
                            "B6": "62",
                            "A7": "Subscriptions",
                            "B7": "45",
                            "A8": "Transportation",
                            "B8": "38",
                            "A9": "Entertainment",
                            "B9": "25",
                            "A10": "",
                            "A11": "Total Spent",
                            "B11": "=SUM(B5:B9)",
                            "A12": "Remaining",
                            "B12": "=B2-B11"
                        ]
                    ),
                    sheet(
                        id: "sheet_budget_tracker_february",
                        name: "February 2026",
                        rows: 10,
                        columns: 3,
                        values: [
                            "A1": "Category",
                            "B1": "Amount",
                            "A2": "Monthly Budget",
                            "B2": "500",
                            "A4": "Spending",
                            "A5": "Groceries",
                            "B5": "210",
                            "A6": "Dining Out",
                            "B6": "75",
                            "A7": "Subscriptions",
                            "B7": "45",
                            "A8": "Transportation",
                            "B8": "52",
                            "A9": "Entertainment",
                            "B9": "40",
                            "A10": "Total Spent",
                            "B10": "=SUM(B5:B9)"
                        ]
                    )
                ]
            ),

            // file_sheet_experiment_results: sheets-sim content
            SpreadsheetFile(
                id: "file_sheet_experiment_results",
                title: "2026 Open House Volunteers",
                sheets: [
                    sheet(
                        id: "sheet_experiment_results_run_1",
                        name: "Volunteers",
                        rows: 7,
                        columns: 4,
                        values: [
                            "A1": "Name",
                            "B1": "Shift",
                            "C1": "Lead",
                            "D1": "Status",
                            "A2": "Ava",
                            "B2": "Morning",
                            "C2": "Ops",
                            "D2": "Confirmed",
                            "A3": "Sam",
                            "B3": "Afternoon",
                            "C3": "Product Lead",
                            "D3": "Confirmed",
                            "A4": "Mia",
                            "B4": "Check-in",
                            "C4": "QA Lead",
                            "D4": "Pending"
                        ]
                    )
                ]
            ),

            // file_sheet_task_tracker: sheets-sim content
            SpreadsheetFile(
                id: "file_sheet_task_tracker",
                title: "Device Testing Tasks",
                sheets: [
                    sheet(
                        id: "sheet_task_tracker_apps",
                        name: "Apps",
                        rows: 25,
                        columns: 2,
                        values: [
                            "A1": "App",
                            "B1": "Status",
                            "A2": "Weather",
                            "B2": "In Progress",
                            "A3": "FilmoMatic",
                            "B3": "In Progress",
                            "A4": "Notes",
                            "B4": "In Progress",
                            "A5": "Calculator",
                            "B5": "In Progress",
                            "A6": "Messages",
                            "B6": "In Progress",
                            "A7": "QuickBite",
                            "B7": "In Progress",
                            "A8": "Weather",
                            "B8": "In Progress",
                            "A9": "StayFinder",
                            "B9": "In Progress",
                            "A10": "TicketBox",
                            "B10": "In Progress",
                            "A11": "TasteRank",
                            "B11": "In Progress",
                            "A12": "SplitPay",
                            "B12": "In Progress",
                            "A13": "CityRide",
                            "B13": "In Progress",
                            "A14": "FirstTrust Bank",
                            "B14": "In Progress",
                            "A15": "SkyTrip",
                            "B15": "In Progress",
                            "A16": "ScoreZone",
                            "B16": "In Progress",
                            "A17": "TeamChat",
                            "B17": "In Progress",
                            "A18": "DineSpot",
                            "B18": "In Progress",
                            "A19": "Mail",
                            "B19": "In Progress",
                            "A20": "TrailBlaze",
                            "B20": "In Progress",
                            "A21": "CalTrack",
                            "B21": "In Progress",
                            "A22": "MegaMart",
                            "B22": "In Progress",
                            "A23": "CloudDrive",
                            "B23": "In Progress",
                            "A24": "CloudSheets",
                            "B24": "In Progress",
                            "A25": "CloudDocs",
                            "B25": "In Progress"
                        ]
                    ),
                    sheet(
                        id: "sheet_task_tracker_tasks",
                        name: "Tasks",
                        rows: 7,
                        columns: 4,
                        values: [
                            "A1": "Task",
                            "B1": "Owner",
                            "C1": "Due",
                            "D1": "Status",
                            "A2": "Match Sheets UI",
                            "B2": "Jordan Avery",
                            "C2": "Mar 6",
                            "D2": "In Progress",
                            "A3": "Seed task workbook",
                            "B3": "QA Lead",
                            "C3": "Mar 6",
                            "D3": "Done",
                            "A4": "Review cell editing",
                            "B4": "Product Lead",
                            "C4": "Mar 7",
                            "D4": "Pending"
                        ]
                    )
                ]
            ),

            // file_sheet_event_planning: sheets-sim content
            SpreadsheetFile(
                id: "file_sheet_event_planning",
                title: "League Operations Master",
                sheets: [
                    sheet(
                        id: "sheet_event_planning_checklist",
                        name: "Master",
                        rows: 5,
                        columns: 4,
                        values: [
                            "A1": "Division",
                            "B1": "Coach",
                            "C1": "Updated",
                            "D1": "Status",
                            "A2": "Division A",
                            "B2": "Product Lead",
                            "C2": "Mar 3",
                            "D2": "Ready",
                            "A3": "Division B",
                            "B3": "Jordan Avery",
                            "C3": "Mar 3",
                            "D3": "Review"
                        ]
                    )
                ]
            ),

            // 6 unique spreadsheets from sheets-sim
            SpreadsheetFile(
                id: "file_sheet_ml_tea",
                title: "ML Reading Group AY25-26",
                sheets: [
                    sheet(
                        id: "sheet_ml_tea_schedule",
                        name: "Schedule",
                        rows: 6,
                        columns: 4,
                        values: [
                            "A1": "Week",
                            "B1": "Host",
                            "C1": "Topic",
                            "D1": "Status",
                            "A2": "Feb 26",
                            "B2": "Jordan Avery",
                            "C2": "Recommenders",
                            "D2": "Confirmed",
                            "A3": "Mar 5",
                            "B3": "QA Lead",
                            "C3": "Evaluation",
                            "D3": "Planned"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_untitled",
                title: "Untitled spreadsheet",
                sheets: [
                    sheet(
                        id: "sheet_untitled_1",
                        name: "Sheet1",
                        rows: 5,
                        columns: 3,
                        values: [:]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_planning_sync_0218",
                title: "Planning Sync - 2026/02/18 14:30",
                sheets: [
                    sheet(
                        id: "sheet_rlj_notes",
                        name: "Notes",
                        rows: 6,
                        columns: 3,
                        values: [
                            "A1": "Topic",
                            "B1": "Owner",
                            "C1": "Next",
                            "A2": "Platform parity",
                            "B2": "Product Lead",
                            "C2": "Review"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_phd_director",
                title: "Imported Committee Notes.xlsx",
                sheets: [
                    sheet(
                        id: "sheet_phd_director_agenda",
                        name: "Agenda",
                        rows: 6,
                        columns: 3,
                        values: [
                            "A1": "Item",
                            "B1": "Lead",
                            "C1": "Status",
                            "A2": "Program update",
                            "B2": "Jordan Avery",
                            "C2": "Discuss"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_partner_sync_0214",
                title: "Partner Sync - 2026/02/14 15:00",
                sheets: [
                    sheet(
                        id: "sheet_ljr_0214",
                        name: "Sheet1",
                        rows: 5,
                        columns: 3,
                        values: [
                            "A1": "Topic",
                            "B1": "Lead",
                            "C1": "Status",
                            "A2": "Performance",
                            "B2": "QA Lead",
                            "C2": "Open"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_launch_planning_0213",
                title: "Launch Planning - 2026/02/13 13:00",
                sheets: [
                    sheet(
                        id: "sheet_ljr_0213",
                        name: "Sheet1",
                        rows: 5,
                        columns: 3,
                        values: [
                            "A1": "Topic",
                            "B1": "Lead",
                            "C1": "Status",
                            "A2": "Planning",
                            "B2": "Jordan Avery",
                            "C2": "Open"
                        ]
                    )
                ]
            ),

            // 7 unique spreadsheets from drive-sim
            SpreadsheetFile(
                id: "file_sheet_launch_tracker",
                title: "Launch Tracker",
                sheets: [
                    sheet(
                        id: "sheet_launch_tracker_main",
                        name: "Tracker",
                        rows: 7,
                        columns: 5,
                        values: [
                            "A1": "Task",
                            "B1": "Owner",
                            "C1": "Status",
                            "A2": "Finalize copy",
                            "B2": "Nina",
                            "C2": "In Review",
                            "A3": "QA sweep",
                            "B3": "Marco",
                            "C3": "Blocked",
                            "A4": "Support brief",
                            "B4": "Avery",
                            "C4": "Done"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_headcount_plan",
                title: "Headcount Plan",
                sheets: [
                    sheet(
                        id: "sheet_headcount_plan_main",
                        name: "Plan",
                        rows: 6,
                        columns: 4,
                        values: [
                            "A1": "Role",
                            "B1": "Quarter",
                            "C1": "Count",
                            "A2": "Designer",
                            "B2": "Q3",
                            "C2": "2",
                            "A3": "PM",
                            "B3": "Q3",
                            "C3": "1",
                            "A4": "Support Ops",
                            "B4": "Q4",
                            "C4": "1"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_interview_roster",
                title: "Interview Roster",
                sheets: [
                    sheet(
                        id: "sheet_interview_roster_main",
                        name: "Roster",
                        rows: 7,
                        columns: 5,
                        values: [
                            "A1": "Participant",
                            "B1": "Segment",
                            "C1": "Status",
                            "A2": "P-104",
                            "B2": "New user",
                            "C2": "Scheduled",
                            "A3": "P-107",
                            "B3": "Admin",
                            "C3": "Complete",
                            "A4": "P-109",
                            "B4": "Manager",
                            "C4": "Reschedule"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_expense_rollup",
                title: "Expense Rollup",
                sheets: [
                    sheet(
                        id: "sheet_expense_rollup_main",
                        name: "Expenses",
                        rows: 6,
                        columns: 4,
                        values: [
                            "A1": "Category",
                            "B1": "Budget",
                            "C1": "Actual",
                            "A2": "Travel",
                            "B2": "4200",
                            "C2": "3890",
                            "A3": "Research",
                            "B3": "2800",
                            "C3": "2510"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_budget_review",
                title: "Budget Review",
                sheets: [
                    sheet(
                        id: "sheet_budget_review_main",
                        name: "Review",
                        rows: 7,
                        columns: 4,
                        values: [
                            "A1": "Line item",
                            "B1": "Owner",
                            "C1": "Status",
                            "A2": "Team offsite",
                            "B2": "Finance",
                            "C2": "Approved",
                            "A3": "Research stipend",
                            "B3": "Avery",
                            "C3": "Review"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_event_run_of_show",
                title: "Event Run of Show",
                sheets: [
                    sheet(
                        id: "sheet_event_run_of_show_main",
                        name: "Run of Show",
                        rows: 8,
                        columns: 5,
                        values: [
                            "A1": "Time",
                            "B1": "Session",
                            "C1": "Owner",
                            "A2": "9:00",
                            "B2": "Welcome",
                            "C2": "Mara",
                            "A3": "9:30",
                            "B3": "Product demo",
                            "C3": "Avery"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_support_escalations",
                title: "Support Escalation Tracker",
                sheets: [
                    sheet(
                        id: "sheet_support_escalations_main",
                        name: "Escalations",
                        rows: 7,
                        columns: 5,
                        values: [
                            "A1": "Case",
                            "B1": "Severity",
                            "C1": "Owner",
                            "A2": "CS-214",
                            "B2": "High",
                            "C2": "Nadia",
                            "A3": "CS-219",
                            "B3": "Medium",
                            "C3": "Eric"
                        ]
                    )
                ]
            ),

            // ── Benchmark diversification: additional spreadsheets ──
            SpreadsheetFile(
                id: "file_sheet_monthly_expense",
                title: "Monthly Expense Log",
                sheets: [
                    sheet(
                        id: "sheet_monthly_expense_main",
                        name: "March 2026",
                        rows: 15,
                        columns: 4,
                        values: [
                            "A1": "Date", "B1": "Category", "C1": "Amount", "D1": "Note",
                            "A2": "Mar 1", "B2": "Rent", "C2": "2450", "D2": "Monthly",
                            "A3": "Mar 3", "B3": "Groceries", "C3": "87.45", "D3": "Whole Foods",
                            "A4": "Mar 5", "B4": "Dining", "C4": "42.18", "D4": "Sushi Ran",
                            "A5": "Mar 7", "B5": "Transport", "C5": "16.50", "D5": "CityRide",
                            "A6": "Mar 9", "B6": "Subscriptions", "C6": "15.99", "D6": "Streaming",
                            "A7": "Mar 12", "B7": "Groceries", "C7": "62.30", "D7": "",
                            "A8": "Mar 14", "B8": "Utilities", "C8": "78.20", "D8": "PG&E",
                            "A10": "", "A11": "Total", "C11": "=SUM(C2:C9)"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_subscription_audit",
                title: "Subscription Audit",
                sheets: [
                    sheet(
                        id: "sheet_sub_audit_main",
                        name: "Active",
                        rows: 12,
                        columns: 4,
                        values: [
                            "A1": "Service", "B1": "Monthly", "C1": "Annual", "D1": "Keep?",
                            "A2": "Streaming", "B2": "15.99", "C2": "191.88", "D2": "Yes",
                            "A3": "Cloud backup", "B3": "9.99", "C3": "119.88", "D3": "Yes",
                            "A4": "Meditation", "B4": "12.99", "C4": "155.88", "D4": "Review",
                            "A5": "Password mgr", "B5": "3.99", "C5": "47.88", "D5": "Yes",
                            "A6": "News", "B6": "4.00", "C6": "48.00", "D6": "Review",
                            "A7": "Fitness app", "B7": "14.99", "C7": "179.88", "D7": "Cancel",
                            "A9": "", "A10": "Total monthly", "B10": "=SUM(B2:B7)"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_travel_budget",
                title: "Travel Budget",
                sheets: [
                    sheet(
                        id: "sheet_travel_catalina",
                        name: "Catalina Trip",
                        rows: 10,
                        columns: 3,
                        values: [
                            "A1": "Item", "B1": "Estimate", "C1": "Actual",
                            "A2": "Lodging (3 nights)", "B2": "981", "C2": "",
                            "A3": "Flights", "B3": "0", "C3": "",
                            "A4": "Ferry", "B4": "76", "C4": "",
                            "A5": "Food", "B5": "300", "C5": "",
                            "A6": "Activities", "B6": "150", "C6": "",
                            "A7": "Transport", "B7": "80", "C7": "",
                            "A9": "Total", "B9": "=SUM(B2:B7)"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_spending_dashboard",
                title: "Spending Dashboard",
                sheets: [
                    sheet(
                        id: "sheet_spending_main",
                        name: "By Category",
                        rows: 15,
                        columns: 3,
                        values: [
                            "A1": "Category", "B1": "This month", "C1": "Avg/month",
                            "A2": "Housing", "B2": "2450", "C2": "2450",
                            "A3": "Food (home)", "B3": "342", "C3": "310",
                            "A4": "Food (out)", "B4": "185", "C4": "220",
                            "A5": "Transport", "B5": "89", "C5": "95",
                            "A6": "Subscriptions", "B6": "62", "C6": "62",
                            "A7": "Entertainment", "B7": "110", "C7": "85",
                            "A8": "Shopping", "B8": "210", "C8": "175",
                            "A10": "Total", "B10": "=SUM(B2:B8)"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_bug_triage",
                title: "Bug Triage Log",
                sheets: [
                    sheet(
                        id: "sheet_bug_triage_main",
                        name: "Open",
                        rows: 12,
                        columns: 4,
                        values: [
                            "A1": "ID", "B1": "Severity", "C1": "Owner", "D1": "Status",
                            "A2": "BUG-204", "B2": "High", "C2": "Sam", "D2": "In progress",
                            "A3": "BUG-205", "B3": "Medium", "C3": "Priya", "D3": "Triaged",
                            "A4": "BUG-207", "B4": "Low", "C4": "Jordan", "D4": "Open",
                            "A5": "BUG-210", "B5": "High", "C5": "Riley", "D5": "In progress",
                            "A6": "BUG-214", "B6": "Medium", "C6": "Sam", "D6": "Open"
                        ]
                    )
                ]
            ),
            SpreadsheetFile(
                id: "file_sheet_qa_matrix",
                title: "QA Test Matrix",
                sheets: [
                    sheet(
                        id: "sheet_qa_matrix_main",
                        name: "Coverage",
                        rows: 10,
                        columns: 5,
                        values: [
                            "A1": "Feature", "B1": "iOS", "C1": "Android", "D1": "Web", "E1": "API",
                            "A2": "Login", "B2": "Pass", "C2": "Pass", "D2": "Pass", "E2": "Pass",
                            "A3": "Onboarding", "B3": "Pass", "C3": "Blocked", "D3": "Pass", "E3": "Pass",
                            "A4": "Discover", "B4": "Pass", "C4": "Pass", "D4": "Fail", "E4": "Pass",
                            "A5": "Checkout", "B5": "In test", "C5": "In test", "D5": "Pass", "E5": "Pass"
                        ]
                    )
                ]
            )
        ]
    }

    // MARK: - Presentations (19 total)

    private static func makePresentations() -> [PresentationFile] {
        [
            // 10 from slides-sim (9 unique + 1 shared Quarterly Review)
            PresentationFile(
                id: "file_slides_speaking_skills",
                title: "Conference Practice Deck",
                themeName: "Slate",
                slides: [
                    SlidePage(
                        id: "slide_speaking_skills_1",
                        title: "Journeys: A True User Distribution Benchmark for Web Agents",
                        body: "Benchmark Working Group",
                        layout: .titleOnly
                    ),
                    SlidePage(
                        id: "slide_speaking_skills_2",
                        title: "What are Web Agents? LLM Web Agents?",
                        body: """
                        Web agents are autonomous actors that can take intended actions on the internet
                        LLM web agents incorporate LLMs as the decision-maker, taking relevant input and outputting computer-based actions
                        LLMs allow web agents to expand from traditional, automated processes through the ability of LLMs.
                        """,
                        layout: .titleBody
                    ),
                    SlidePage(
                        id: "slide_speaking_skills_3",
                        title: "Why Autonomous Web Agents?",
                        body: """
                        Many of our daily tasks are performed on the computer/internet
                        Potential to automate large amounts of menial tasks
                        Augmenting human capabilities + saving time!
                        """,
                        layout: .titleBody
                    ),
                    SlidePage(
                        id: "slide_speaking_skills_4",
                        title: "OPENCLAW",
                        body: "Browser Use\nWebGPT: Improving the factual accuracy of language models through web browsing",
                        layout: .section
                    )
                ]
            ),
            PresentationFile(
                id: "file_slides_superintelligence",
                title: "[Draft] Autonomous Agents",
                themeName: "Signal",
                slides: [
                    SlidePage(id: "slide_superintelligence_1", title: "Autonomous Agents", body: "19 Feb", layout: .titleOnly),
                    SlidePage(id: "slide_superintelligence_2", title: "Agenda", body: "Threat models\nResearch gaps\nWhy benchmarks matter", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_frontend_codegen",
                title: "Frontend Codegen Review",
                themeName: "Dark",
                slides: [
                    SlidePage(id: "slide_frontend_codegen_1", title: "Frontend code generation", body: "Benchmarks for UI synthesis and repair", layout: .titleOnly),
                    SlidePage(id: "slide_frontend_codegen_2", title: "Open questions", body: "What should agents optimize for?\nVisual fidelity\nFunctional correctness", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_life_pittsburgh_s26",
                title: "S26 City Guide",
                themeName: "Canvas",
                slides: [
                    SlidePage(id: "slide_life_pgh_s26_1", title: "City Guide", body: "Neighborhood highlights", layout: .titleOnly),
                    SlidePage(id: "slide_life_pgh_s26_2", title: "Where to explore", body: "Riverside\nOld Town\nMarket Square", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_life_pittsburgh_s25",
                title: "S25 City Guide",
                themeName: "Canvas",
                slides: [
                    SlidePage(id: "slide_life_pgh_s25_1", title: "City Guide", body: "Winter comic strip moments", layout: .titleOnly),
                    SlidePage(id: "slide_life_pgh_s25_2", title: "Neighborhoods", body: "Garden District\nRiverside\nNorth Market", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_healthcare_startup",
                title: "Healthcare Startup Criteria",
                themeName: "Neutral",
                slides: [
                    SlidePage(id: "slide_healthcare_1", title: "Healthcare Startup Criteria", body: "Product Strategy Team", layout: .titleOnly),
                    SlidePage(id: "slide_healthcare_2", title: "Criteria", body: "Workflow depth\nClinical ROI\nProvider love", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_temperature_check",
                title: "Signal Check",
                themeName: "Minimal",
                slides: [
                    SlidePage(id: "slide_temperature_1", title: "Signal Check", body: "How benchmark results feel this week", layout: .titleOnly),
                    SlidePage(id: "slide_temperature_2", title: "Signals", body: "Models improve fast\nUnderstanding lags\nReliable evals matter", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_cohere_talk",
                title: "Agent Systems Talk",
                themeName: "Neutral",
                slides: [
                    SlidePage(id: "slide_cohere_1", title: "Agent Systems Talk", body: "Information and skills that are valuable are changing so quickly", layout: .titleOnly),
                    SlidePage(id: "slide_cohere_2", title: "Takeaways", body: "Agency\nReliability\nDistribution shift", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_athena_pitch",
                title: "Product Pitch",
                themeName: "Pitch",
                slides: [
                    SlidePage(id: "slide_athena_1", title: "Product Pitch", body: "Team overview and product brief", layout: .titleOnly),
                    SlidePage(id: "slide_athena_2", title: "Why now", body: "Clinical demand\nFaster workflows\nSafer copilots", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_quarterly_review",
                title: "Quarterly Review",
                themeName: "Classic",
                slides: [
                    SlidePage(id: "slide_quarterly_review_1", title: "Quarterly Review", body: "Archived summary for Q4.", layout: .titleOnly),
                    SlidePage(id: "slide_quarterly_review_2", title: "Highlights", body: "Shipped dashboard refresh and improved reporting accuracy.", layout: .titleBody)
                ]
            ),

            // 3 from docs-sim/sheets-sim
            PresentationFile(
                id: "file_slides_team_update",
                title: "Team Update",
                themeName: "Slate",
                slides: [
                    SlidePage(id: "slide_team_update_1", title: "Team Update", body: "Progress against launch goals and open actions.", layout: .titleBody),
                    SlidePage(id: "slide_team_update_2", title: "Wins", body: "Retention up 7 percent week over week.\nSupport backlog down 18 percent.", layout: .titleBody),
                    SlidePage(id: "slide_team_update_3", title: "Next Steps", body: "Lock scope, confirm QA signoff, publish readiness note.", layout: .section)
                ]
            ),
            PresentationFile(
                id: "file_slides_project_pitch",
                title: "Project Pitch",
                themeName: "Neutral",
                slides: [
                    SlidePage(id: "slide_project_pitch_1", title: "Project Pitch", body: "Why this workflow matters for field teams.", layout: .titleOnly),
                    SlidePage(id: "slide_project_pitch_2", title: "Problem", body: "Current process takes too many taps and breaks context.", layout: .titleBody),
                    SlidePage(id: "slide_project_pitch_3", title: "Proposal", body: "Bundle the highest-value actions into a dedicated flow.", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_workshop_slides",
                title: "Workshop Slides",
                themeName: "Canvas",
                slides: [
                    SlidePage(id: "slide_workshop_1", title: "Workshop", body: "Facilitator notes and breakout agenda.", layout: .titleBody),
                    SlidePage(id: "slide_workshop_2", title: "Exercises", body: "Map the end-to-end customer handoff.", layout: .section)
                ]
            ),

            // 6 from drive-sim
            PresentationFile(
                id: "file_slides_all_hands_story",
                title: "All Hands Storyline",
                themeName: "Slate",
                slides: [
                    SlidePage(id: "slide_all_hands_story_1", title: "All Hands", body: "What changed, what shipped, and where we are investing next.", layout: .titleBody),
                    SlidePage(id: "slide_all_hands_story_2", title: "Wins", body: "Activation is up, support volume is down, and launch prep is on track.", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_creative_review",
                title: "Creative Review",
                themeName: "Neutral",
                slides: [
                    SlidePage(id: "slide_creative_review_1", title: "Creative Review", body: "New homepage illustration direction and launch art options.", layout: .titleOnly),
                    SlidePage(id: "slide_creative_review_2", title: "Recommendation", body: "Use the simpler composition and keep labels minimal.", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_workshop_deck",
                title: "Workshop Deck",
                themeName: "Classic",
                slides: [
                    SlidePage(id: "slide_workshop_deck_1", title: "Workshop", body: "Plan for the kickoff session and breakout format.", layout: .titleOnly),
                    SlidePage(id: "slide_workshop_deck_2", title: "Discussion prompts", body: "Map the current workflow, identify blockers, and propose one simplified path.", layout: .section)
                ]
            ),
            PresentationFile(
                id: "file_slides_board_prep",
                title: "Board Prep",
                themeName: "Slate",
                slides: [
                    SlidePage(id: "slide_board_prep_1", title: "Board Prep", body: "Performance update, risks, and next-quarter priorities.", layout: .titleBody),
                    SlidePage(id: "slide_board_prep_2", title: "Risks", body: "Staffing timelines and support readiness remain the main watch items.", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_partner_kickoff",
                title: "Partner Kickoff",
                themeName: "Bright",
                slides: [
                    SlidePage(id: "slide_partner_kickoff_1", title: "Kickoff", body: "Launch sequence, partner motions, and readiness checkpoints.", layout: .titleBody),
                    SlidePage(id: "slide_partner_kickoff_2", title: "Next steps", body: "Lock event owners, finalize asset list, and confirm support coverage.", layout: .section)
                ]
            ),
            PresentationFile(
                id: "file_slides_design_system_update",
                title: "Design System Update",
                themeName: "Neutral",
                slides: [
                    SlidePage(id: "slide_design_system_update_1", title: "Design System", body: "Component updates, documentation improvements, and migration timing.", layout: .titleBody),
                    SlidePage(id: "slide_design_system_update_2", title: "Recommendation", body: "Ship the new card system first and migrate templates in phases.", layout: .titleBody)
                ]
            ),

            // ── Benchmark diversification: additional presentations ──
            PresentationFile(
                id: "file_slides_product_demo",
                title: "Product Demo Deck",
                themeName: "Slate",
                slides: [
                    SlidePage(id: "slide_demo_1", title: "Product Demo", body: "Q2 Preview Release", layout: .titleOnly),
                    SlidePage(id: "slide_demo_2", title: "What's new", body: "Personalized Discover, faster Checkout, refreshed Home.", layout: .titleBody),
                    SlidePage(id: "slide_demo_3", title: "Live walkthrough", body: "Home -> Discover -> Detail -> Checkout", layout: .titleBody),
                    SlidePage(id: "slide_demo_4", title: "Numbers", body: "Activation +8%, task completion +12%, p95 -18%.", layout: .titleBody)
                ]
            ),
            PresentationFile(
                id: "file_slides_all_hands_q2",
                title: "Q2 All-Hands",
                themeName: "Slate",
                slides: [
                    SlidePage(id: "slide_allhands_q2_1", title: "Q2 All-Hands", body: "Where we are, what's next", layout: .titleOnly),
                    SlidePage(id: "slide_allhands_q2_2", title: "Q1 recap", body: "Mobile launch shipped, API v3 entered beta, onboarding funnel improved.", layout: .titleBody),
                    SlidePage(id: "slide_allhands_q2_3", title: "Q2 priorities", body: "Personalization, Reliability, Onboarding polish.", layout: .titleBody),
                    SlidePage(id: "slide_allhands_q2_4", title: "Team focus", body: "Platform: API v3 GA. Mobile: Personalized Discover. Infra: Latency.", layout: .titleBody)
                ]
            )
        ]
    }

    // MARK: - Recent Activity (union of all 4 apps)

    private static func makeRecentActivity() -> [RecentActivity] {
        [
            // From sheets-sim
            activity("activity_sheets_1", "Opened Device Testing Tasks in Sheets", "file_sheet_task_tracker", "2026-03-06T15:12:00Z"),
            activity("activity_sheets_2", "Updated Tentative Schedule: 2026 Open House", "file_sheet_budget_tracker", "2026-03-06T11:30:00Z"),

            // From docs-sim
            activity("activity_docs_1", "Updated Mobile Launch Plan", "file_doc_meeting_notes", "2026-03-05T10:20:00Z"),
            activity("activity_docs_2", "Edited Compute Access Runbook", "file_doc_project_plan", "2026-03-05T09:35:00Z"),

            // From drive-sim
            activity("activity_drive_2", "Opened Q3 Planning Brief", "file_doc_q3_planning_brief", "2026-03-05T08:30:00Z"),
            activity("activity_drive_1", "Updated Launch Tracker", "file_sheet_launch_tracker", "2026-03-05T08:20:00Z"),
            activity("activity_drive_0", "Updated Design System Update", "file_slides_design_system_update", "2026-03-05T07:42:00Z"),
            activity("activity_drive_2b", "Reviewed Client Workshop Agenda", "file_doc_client_workshop_agenda", "2026-03-05T07:36:00Z"),

            // From slides-sim
            activity("activity_slides_1", "Updated Weekly Update", "file_doc_weekly_update", "2026-03-05T07:55:00Z"),
            activity("activity_slides_0", "Opened Conference Practice Deck in Slides", "file_slides_speaking_skills", "2026-03-05T06:40:00Z"),

            // From docs-sim
            activity("activity_docs_3", "Updated Agent Systems Review", "file_doc_weekly_update", "2026-03-04T16:15:00Z"),

            // From sheets-sim
            activity("activity_sheets_3", "Reviewed 2026 Open House Volunteers", "file_sheet_experiment_results", "2026-03-04T16:15:00Z"),

            // From drive-sim
            activity("activity_drive_3b", "Edited Event Run of Show", "file_sheet_event_run_of_show", "2026-03-04T18:08:00Z"),
            activity("activity_drive_3", "Reviewed Sprint Retro Notes", "file_doc_sprint_retro", "2026-03-04T09:45:00Z"),

            // From slides-sim
            activity("activity_slides_3", "Edited Project Plan", "file_doc_project_plan", "2026-03-04T11:20:00Z"),
            activity("activity_slides_4", "Created folder Q2 Launch", nil, "2026-03-04T09:00:00Z"),

            // From slides-sim
            activity("activity_slides_5", "Opened Meeting Notes from Drive", "file_doc_meeting_notes", "2026-03-03T18:10:00Z"),

            // From docs-sim
            activity("activity_docs_4", "Reviewed Planning Notes 2.0", "file_doc_research_outline", "2026-03-03T13:05:00Z"),

            // From sheets-sim
            activity("activity_sheets_4", "Opened League Operations Master", "file_sheet_event_planning", "2026-03-03T09:40:00Z"),

            // From slides-sim
            activity("activity_slides_6", "Updated Budget Tracker", "file_sheet_budget_tracker", "2026-03-02T16:25:00Z"),

            // From docs-sim
            activity("activity_docs_5", "Shared Content Queue", "file_doc_hiring_notes", "2026-03-02T11:50:00Z"),

            // From drive-sim
            activity("activity_drive_4", "Edited Customer Interview Themes", "file_doc_interview_themes", "2026-03-01T10:15:00Z"),
            activity("activity_drive_4b", "Prepared Board Prep", "file_slides_board_prep", "2026-03-01T17:00:00Z"),

            // From docs-sim
            activity("activity_docs_6", "Created Untitled document", "file_doc_travel_checklist", "2026-03-01T18:10:00Z"),

            // From docs-sim
            activity("activity_docs_7", "Updated Untitled document", "file_doc_todo_capture", "2026-02-28T17:40:00Z"),

            // From slides-sim
            activity("activity_slides_7", "Reviewed Research Outline", "file_doc_research_outline", "2026-02-27T12:10:00Z"),

            // From drive-sim
            activity("activity_drive_5", "Shared Vendor Checklist", "file_doc_vendor_checklist", "2026-02-27T15:30:00Z"),

            // From docs-sim
            activity("activity_docs_8", "Drafted Untitled document", "file_doc_research_invite", "2026-02-27T09:20:00Z"),

            // From sheets-sim
            activity("activity_sheets_5", "Edited ML Reading Group AY25-26", "file_sheet_ml_tea", "2026-02-26T13:05:00Z"),

            // From slides-sim
            activity("activity_slides_8", "Refreshed Experiment Results", "file_sheet_experiment_results", "2026-02-26T09:35:00Z"),

            // From drive-sim
            activity("activity_drive_6", "Viewed Headcount Plan", "file_sheet_headcount_plan", "2026-02-25T13:00:00Z"),

            // From sheets-sim
            activity("activity_sheets_6", "Created Untitled spreadsheet", "file_sheet_untitled", "2026-02-23T09:00:00Z"),

            // From drive-sim
            activity("activity_drive_7", "Presented Creative Review", "file_slides_creative_review", "2026-02-22T17:20:00Z"),

            // From slides-sim
            activity("activity_slides_2", "Reviewed [Draft] Autonomous Agents", "file_slides_superintelligence", "2026-02-19T16:55:00Z"),

            // From sheets-sim
            activity("activity_sheets_7", "Reviewed Imported Committee Notes.xlsx", "file_sheet_phd_director", "2026-02-17T12:00:00Z"),

            // From sheets-sim
            activity("activity_sheets_8", "Opened Partner Sync - 2026/02/14 15:00", "file_sheet_partner_sync_0214", "2026-02-14T15:00:00Z"),

            // From drive-sim
            activity("activity_drive_8", "Archived Archive Notes", "file_doc_archive_notes", "2026-01-12T10:20:00Z")
        ]
    }

    // MARK: - Helpers

    private static func folder(
        _ id: String,
        _ name: String,
        _ parentFolderId: String?,
        updated: String,
        starred: Bool = false,
        shared: Bool = false,
        trashed: Bool = false,
        ownerName: String = "Jordan Avery"
    ) -> WorkspaceFolder {
        WorkspaceFolder(
            id: id,
            name: name,
            parentFolderId: parentFolderId,
            createdAt: date("2025-11-01T08:00:00Z"),
            updatedAt: date(updated),
            starred: starred,
            shared: shared,
            trashed: trashed,
            ownerName: ownerName
        )
    }

    private static func file(
        id: String,
        name: String,
        type: WorkspaceFileType,
        parent: String?,
        created: String,
        updated: String,
        starred: Bool = false,
        shared: Bool = false,
        trashed: Bool = false,
        size: String,
        permissions: [FilePermission],
        comments: [FileComment],
        lastOpened: String?,
        ownerName: String = "Jordan Avery"
    ) -> WorkspaceFile {
        WorkspaceFile(
            id: id,
            name: name,
            fileType: type,
            parentFolderId: parent,
            createdAt: date(created),
            updatedAt: date(updated),
            starred: starred,
            trashed: trashed,
            shared: shared,
            ownerName: ownerName,
            accessRole: .editor,
            sizeDescription: size,
            permissions: permissions,
            linkSettings: SharedLinkSettings(
                visibility: shared ? .anyoneWithLink : .restricted,
                defaultRole: shared ? .viewer : .editor,
                copyCount: shared ? 1 : 0
            ),
            comments: comments,
            lastOpenedAt: lastOpened.map(date)
        )
    }

    private static func permissions(_ names: [String], role: AccessRole) -> [FilePermission] {
        names.map { name in
            FilePermission(id: "permission_\(name.stableSlug)", personName: name, role: role)
        }
    }

    private static func comment(_ id: String, _ author: String, _ body: String, _ createdAt: String) -> FileComment {
        FileComment(id: id, authorName: author, body: body, createdAt: date(createdAt))
    }

    private static func activity(_ id: String, _ summary: String, _ targetFileId: String?, _ createdAt: String) -> RecentActivity {
        RecentActivity(id: id, summary: summary, targetFileId: targetFileId, createdAt: date(createdAt))
    }

    private static func document(id: String, title: String, body: String) -> DocumentFile {
        DocumentFile(
            id: id,
            title: title,
            body: body,
            formatting: DocumentFormattingState(
                paragraphStyle: .normal,
                listStyle: .none,
                alignment: .leading,
                bold: false,
                italic: false,
                underline: false,
                suggestionModeEnabled: false
            ),
            blocks: makeBlocks(from: body)
        )
    }

    private static func makeBlocks(from body: String) -> [DocumentBlock] {
        body
            .components(separatedBy: "\n")
            .enumerated()
            .map { index, line in
                DocumentBlock(
                    id: "block_\(index + 1)",
                    text: line,
                    paragraphStyle: index == 0 ? .title : .normal
                )
            }
    }

    private static func sheet(id: String, name: String, rows: Int, columns: Int, values: [String: String]) -> SpreadsheetSheet {
        SpreadsheetSheet(
            id: id,
            name: name,
            rowCount: rows,
            columnCount: columns,
            cells: values
                .sorted(by: { $0.key < $1.key })
                .map { SpreadsheetCell(address: $0.key, rawValue: $0.value) }
        )
    }

    private static func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
