import Cocoa

class KeystrokeSimulator {
    static func simulatePaste() {
        // Small delay to let the OS clipboard settle before triggering paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let source = CGEventSource(stateID: .combinedSessionState)
            
            // Virtual Keycode for 'v' is 9
            let vKeyCode: CGKeyCode = 9
            
            guard let pasteDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else {
                print("Failed to create keyboard down event")
                return
            }
            pasteDown.flags = .maskCommand
            
            guard let pasteUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
                print("Failed to create keyboard up event")
                return
            }
            pasteUp.flags = .maskCommand
            
            pasteDown.post(tap: .cghidEventTap)
            pasteUp.post(tap: .cghidEventTap)
            print("Keystroke simulation posted: Cmd+V")
        }
    }
    
    // Check if the app has accessibility permissions (not always strict for posting, but good to know)
    static func checkAccessibilityPermissions(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
