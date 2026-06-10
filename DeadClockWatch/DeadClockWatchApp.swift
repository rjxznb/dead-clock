import SwiftUI

@main
struct DeadClockWatchApp: App {
    init() {
        WatchSync.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchCountdownView()
        }
    }
}
