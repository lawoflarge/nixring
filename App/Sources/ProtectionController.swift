import Foundation
import CallKit

/// Thin async wrapper around `CXCallDirectoryManager` for reloading the Call Directory
/// extension, reading its enabled status, and deep-linking to its Settings pane.
enum ProtectionController {
    static let callDirID = "com.levinschwab.nixring.calldir"

    static func reload() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: callDirID) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    static func status() async -> CXCallDirectoryManager.EnabledStatus {
        await withCheckedContinuation { (cont: CheckedContinuation<CXCallDirectoryManager.EnabledStatus, Never>) in
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: callDirID) { status, _ in
                cont.resume(returning: status)
            }
        }
    }

    /// Deep-link straight to the app's Call Directory toggle in Settings (iOS 13.4+).
    static func openSettings() {
        CXCallDirectoryManager.sharedInstance.openSettings { _ in }
    }
}
