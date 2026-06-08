import Foundation

struct SeededWorkspaceRepository: WorkspaceRepository {
    func loadWorkspaces() throws -> [Workspace] {
        SeedDataFactory.makeSeededWorkspaces()
    }
}
