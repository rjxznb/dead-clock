import SwiftUI

@main
struct DeadClockApp: App {
    var body: some Scene {
        WindowGroup {
            CountdownView()
                .preferredColorScheme(.dark)
        }
    }
}
