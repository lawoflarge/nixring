import Foundation

/// The AdMob blocks of this app.
///
/// The three placeholders are replaced by the roll out script once the blocks
/// exist in AdMob. A Debug build never loads any of them: `AdConfiguration.app`
/// swaps them for Google's official test blocks.
///
/// The two app extensions never see any of this. Nothing advertising is linked
/// into a Call Directory or a Message Filter extension.
extension AdConfiguration {
    static let nixring = AdConfiguration.app(
        applicationID: "ca-app-pub-6563643868702361~5471753832",
        bannerUnitID: "ca-app-pub-6563643868702361/6214929219",
        interstitialUnitID: "ca-app-pub-6563643868702361/6167661909")
}
