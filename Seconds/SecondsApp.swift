import SwiftUI

@main
struct SecondsApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-widget") {
                WidgetRenderingCheck()
            } else {
                CountdownEditor()
            }
            #else
            CountdownEditor()
            #endif
        }
    }
}
