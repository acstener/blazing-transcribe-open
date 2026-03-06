import AppKit
import CoreGraphics

/// Injects text into the focused application via CGEvent keyboard events.
/// This is a local macOS system API — no network involved.
/// Requires Accessibility permission.
final class KeyboardInjector {

    /// Type a string into the currently focused app using CGEvent unicode injection.
    func typeText(_ text: String) {
        let utf16 = Array(text.utf16)
        guard !utf16.isEmpty else { return }

        // CGEvent supports up to 20 UTF-16 code units per event
        let chunkSize = 20
        let source = CGEventSource(stateID: .hidSystemState)

        for chunkStart in stride(from: 0, to: utf16.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, utf16.count)
            let chunk = Array(utf16[chunkStart..<chunkEnd])

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                continue
            }

            chunk.withUnsafeBufferPointer { ptr in
                keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: ptr.baseAddress!)
                keyUp.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: ptr.baseAddress!)
            }

            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)

            if chunkEnd < utf16.count {
                usleep(2000) // 2ms delay between chunks
            }
        }
    }

    /// Whether the app has Accessibility permission.
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }
}
