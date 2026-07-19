import SwiftUI

@main
struct NixringApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
                .task { await model.bootstrap() }
        }
    }
}
