import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        Group {
            if model.hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: $model.showPaywall) { PaywallView() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refresh() } }
        }
    }
}

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tag(0)
                .tabItem { Label("Shield", systemImage: "checkmark.shield.fill") }
            BlocklistView()
                .tag(1)
                .tabItem { Label("Blocklist", systemImage: "nosign") }
            SettingsView()
                .tag(2)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .onAppear { tab = model.initialTab }
    }
}
