import Foundation

/// External links used in the paywall and settings. Privacy + Support are hosted on the
/// public GitHub Pages site; Terms is Apple's standard EULA.
enum AppLinks {
    static let privacy = URL(string: "https://nixring.vercel.app/privacy.html")!
    static let support = URL(string: "https://nixring.vercel.app/support.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
