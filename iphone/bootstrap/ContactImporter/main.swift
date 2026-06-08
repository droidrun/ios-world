import UIKit
import Contacts

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        importContacts()
        return true
    }

    private func importContacts() {
        let store = CNContactStore()

        // Find VCF file - check common locations
        let candidates = [
            NSHomeDirectory() + "/Documents/contacts.vcf",
            "/tmp/contacts.vcf"
        ]

        var vcfData: Data?
        for path in candidates {
            if let data = FileManager.default.contents(atPath: path) {
                vcfData = data
                NSLog("ContactImporter: Found VCF at \(path)")
                break
            }
        }

        guard let data = vcfData else {
            NSLog("ContactImporter: No VCF file found")
            return
        }

        // Delete existing contacts first
        let fetchRequest = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])
        var existingIds: [String] = []
        try? store.enumerateContacts(with: fetchRequest) { contact, _ in
            existingIds.append(contact.identifier)
        }
        if !existingIds.isEmpty {
            let deleteRequest = CNSaveRequest()
            for id in existingIds {
                if let contact = try? store.unifiedContact(withIdentifier: id, keysToFetch: []) {
                    deleteRequest.delete(contact.mutableCopy() as! CNMutableContact)
                }
            }
            try? store.execute(deleteRequest)
            NSLog("ContactImporter: Deleted \(existingIds.count) existing contacts")
        }

        // Import contacts from VCF
        do {
            let contacts = try CNContactVCardSerialization.contacts(with: data)
            let saveRequest = CNSaveRequest()
            for contact in contacts {
                saveRequest.add(contact.mutableCopy() as! CNMutableContact, toContainerWithIdentifier: nil)
            }
            try store.execute(saveRequest)
            NSLog("ContactImporter: Imported \(contacts.count) contacts")
        } catch {
            NSLog("ContactImporter: Error - \(error.localizedDescription)")
        }
    }
}
