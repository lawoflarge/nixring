import Foundation
import CallKit
import NixringCore

/// Feeds CallKit the blocked + identified numbers. All the logic lives in the tested
/// `CallDirectoryBuilder`; this class just streams its output in the required sorted order.
///
/// Call Directory is list-based — iOS never calls us per incoming call, so there is no way
/// to count blocked calls. We simply publish the current list whenever iOS asks us to reload.
class CallDirectoryHandler: CXCallDirectoryProvider {

    static let appGroupID = "group.com.levinschwab.nixring"

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        let store = AppGroupStore(groupID: Self.appGroupID)
        let data = store.load()
        let bundled = BundledBlocklist.loadBundled(from: Bundle(for: Self.self))
        let lists = CallDirectoryBuilder.build(data: data, bundled: bundled)

        // We always publish the full list, so drop any previous incremental state first.
        if context.isIncremental {
            context.removeAllBlockingEntries()
            context.removeAllIdentificationEntries()
        }

        for number in lists.blocked {
            context.addBlockingEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(number))
        }
        for entry in lists.identification {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: CXCallDirectoryPhoneNumber(entry.number),
                                           label: entry.label)
        }

        context.completeRequest()
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // iOS reloads the extension automatically; nothing to persist here.
    }
}
