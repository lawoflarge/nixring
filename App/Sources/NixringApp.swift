import SwiftUI

@main
struct NixringApp: App {
    @State private var model = AppModel()
    @State private var ads = AdsController(configuration: .nixring)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                // Nil until the first entitlement check has answered, so a
                // subscriber never sees the consent form or a banner flash by.
                .adKit(ads, isPremium: model.isProIfKnown)
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
                .task { await model.bootstrap() }
        }
    }
}
