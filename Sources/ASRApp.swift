import SwiftUI
import AppKit

@main
struct ASRApp: App {
    @StateObject private var appState = AppState()
    @State private var settingsWindow: NSWindow?
    @State private var aboutWindow: NSWindow?
    
    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(appState: appState)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenSettingsWindow"))) { _ in
                    openSettings()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenAboutWindow"))) { _ in
                    openAbout()
                }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: getMenuBarIcon())
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func getMenuBarIcon() -> String {
        switch appState.status {
        case .recording:
            return "waveform.circle.fill"
        case .uploading, .transcribing:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "exclamationmark.circle.fill"
        case .idle:
            return "waveform"
        }
    }
    
    private func openSettings() {
        if let window = settingsWindow {
            if window.isVisible {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            } else {
                // Re-center and show
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        let view = SettingsView(appState: appState)
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 740),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        // Enforce native window appearance
        let appearance: NSAppearance?
        if appState.selectedTheme == "dark" {
            appearance = NSAppearance(named: .darkAqua)
        } else if appState.selectedTheme == "light" {
            appearance = NSAppearance(named: .aqua)
        } else {
            appearance = nil
        }
        window.appearance = appearance
        window.contentView?.appearance = appearance
        
        window.center()
        window.title = appState.localizedString("settings_title")
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func openAbout() {
        if let window = aboutWindow {
            if window.isVisible {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            } else {
                window.center()
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        let view = AboutView(appState: appState)
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 380),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Enforce native window appearance
        let appearance: NSAppearance?
        if appState.selectedTheme == "dark" {
            appearance = NSAppearance(named: .darkAqua)
        } else if appState.selectedTheme == "light" {
            appearance = NSAppearance(named: .aqua)
        } else {
            appearance = nil
        }
        window.appearance = appearance
        window.contentView?.appearance = appearance
        
        // Liquid Glass window styling
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        window.center()
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        self.aboutWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
