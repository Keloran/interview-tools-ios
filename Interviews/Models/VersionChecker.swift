@preconcurrency import Foundation

struct AppStoreLookupResponse: Decodable, Sendable {
    let resultCount: Int
    let results: [AppStoreApp]
}

struct AppStoreApp: Decodable, Sendable {
    let version: String
    let trackViewUrl: String
    let releaseNotes: String?
}

actor VersionChecker {
    static let shared = VersionChecker()

    private init() {}

    // Fetch latest version from App Store using bundle identifier
    nonisolated func fetchLatestVersion(bundleIdentifier: String) async throws -> (version: String, url: URL, notes: String?)? {
        // Use iTunes Lookup API
        guard var components = URLComponents(string: "https://itunes.apple.com/lookup") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleIdentifier),
            URLQueryItem(name: "country", value: Locale.current.region?.identifier ?? "us")
        ]
        guard let url = components.url else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }
        let decoded = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        guard decoded.resultCount > 0, let app = decoded.results.first, let url = URL(string: app.trackViewUrl) else {
            return nil
        }
        return (version: app.version, url: url, notes: app.releaseNotes)
    }

    // Compare semantic versions (e.g., 1.2.3). Returns true if storeVersion > currentVersion
    nonisolated func isStoreVersionNewer(currentVersion: String, storeVersion: String) -> Bool {
        let current = currentVersion.split(separator: ".").compactMap { Int($0) }
        let store = storeVersion.split(separator: ".").compactMap { Int($0) }
        let count = max(current.count, store.count)
        for i in 0..<count {
            let c = i < current.count ? current[i] : 0
            let s = i < store.count ? store[i] : 0
            if s > c { return true }
            if s < c { return false }
        }
        return false
    }
}

import SwiftUI

// ViewModifier to present update alert easily
struct UpdateAlertModifier: ViewModifier {
    @State private var showAlert = false
    @State private var updateURL: URL?
    @State private var latestVersion: String = ""
    @State private var releaseNotes: String?

    func body(content: Content) -> some View {
        content
            .task {
                await checkForUpdate()
            }
            .alert("Update Available", isPresented: $showAlert, presenting: (updateURL, latestVersion, releaseNotes)) { payload in
                Button("Not Now", role: .cancel) {}
                if let url = payload.0 {
                    Button("Update") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: { payload in
                let version = payload.1
                if let notes = payload.2, !notes.isEmpty {
                    Text("A newer version (\(version)) is available.\n\nWhat's new:\n\n\(notes)")
                } else {
                    Text("A newer version (\(version)) is available on the App Store.")
                }
            }
    }

    @MainActor
    private func checkForUpdate() async {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        do {
            if let info = try await VersionChecker.shared.fetchLatestVersion(bundleIdentifier: bundleId) {
                if VersionChecker.shared.isStoreVersionNewer(currentVersion: currentVersion, storeVersion: info.version) {
                    latestVersion = info.version
                    updateURL = info.url
                    releaseNotes = info.notes
                    showAlert = true
                }
            }
        } catch {
            // Silently ignore errors; we don't want to block launch
            print("Version check failed: \(error)")
        }
    }
}

extension View {
    func appUpdateAlertOnLaunch() -> some View {
        modifier(UpdateAlertModifier())
    }
}

