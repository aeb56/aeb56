import SwiftUI

@main
struct BandFinderApp: App {
    @StateObject private var scanner = BLEScanner()
    @StateObject private var feedback = Feedback()
    @StateObject private var log = SearchLog()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanner)
                .environmentObject(feedback)
                .environmentObject(log)
                .onAppear {
                    // A dead screen means a missed packet. Keep it awake while hunting.
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
