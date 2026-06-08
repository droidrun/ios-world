import Foundation

final class SharedAccountsService {
    static let appGroupID = LedgerService.appGroupID

    private let fileName = "mybank_accounts.json"

    var accountsFileURL: URL {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    func loadAccounts() -> [Account] {
        guard let data = try? Data(contentsOf: accountsFileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Account].self, from: data)) ?? []
    }

    func saveAccounts(_ accounts: [Account]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(accounts)
            try data.write(to: accountsFileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("[Accounts] Failed to write shared accounts: \(error)")
            #endif
        }
    }
}
