import Foundation
import IdentityLookup
import NixringCore

/// Offline SMS filter for texts from unknown senders. Classification runs entirely in
/// `SmsFilterEngine` (unit-tested); message content is never stored or transmitted.
final class MessageFilterExtension: ILMessageFilterExtension {}

extension MessageFilterExtension: ILMessageFilterQueryHandling {

    static let appGroupID = "group.com.levinschwab.nixring"

    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {

        let response = ILMessageFilterQueryResponse()
        let store = AppGroupStore(groupID: Self.appGroupID)
        let data = store.load()

        // SMS filtering is a Pro feature and can be toggled off.
        guard data.settings.smsFilterEnabled, data.settings.isPro, data.smsRules.enabled else {
            response.action = .allow
            completion(response)
            return
        }

        let action = SmsFilterEngine.classify(sender: queryRequest.sender ?? "",
                                              body: queryRequest.messageBody ?? "",
                                              rules: data.smsRules)
        switch action {
        case .allow:
            response.action = .allow
        case .junk:
            response.action = .junk
            store.bumpTextsFiltered(promotion: false)
        case .promotion:
            response.action = .promotion
            store.bumpTextsFiltered(promotion: true)
        }
        completion(response)
    }
}
