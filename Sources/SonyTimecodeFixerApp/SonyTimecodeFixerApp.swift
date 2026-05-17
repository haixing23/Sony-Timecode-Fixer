import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var model: FixerModel?

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        AppDelegate.model?.process(urls)
        sender.reply(toOpenOrPrint: .success)
    }
}

@main
struct SonyTimecodeFixerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var model = FixerModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onAppear {
                    AppDelegate.model = model
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
