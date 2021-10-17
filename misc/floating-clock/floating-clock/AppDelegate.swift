import Cocoa
import SwiftUI

let MIN_WIDTH = CGFloat(125)
let MIN_HEIGHT = CGFloat(12)

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var appData: AppData!

    func applicationDidFinishLaunching(_: Notification) {
        appData = AppData()

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView().environmentObject(appData)

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: contentView)

        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.white.withAlphaComponent(0)
        window.hasShadow = false

        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]
        window.canHide = false

        window.delegate = self

        window.makeKeyAndOrderFront(nil)

        // Hacks to try to address clock disappearing when external monitors are connected or disconnected
        NSLog(window.frame.debugDescription)
        if window.frame.width < MIN_WIDTH || window.frame.height < MIN_HEIGHT {
            window.setFrame(NSRect(x: window.frame.minX, y: window.frame.minY, width: max(window.frame.width, MIN_WIDTH), height: max(window.frame.height, MIN_HEIGHT)), display: false)
        }
        if window.screen == nil {
            let mainScreen = NSScreen.main
            if mainScreen != nil {
                window.setFrame(NSRect(
                    x: mainScreen!.frame.midX,
                    y: mainScreen!.frame.midY,
                    width: MIN_WIDTH,
                    height: MIN_HEIGHT
                ), display: false)
            }
        }

        // Hide in dock and command-tab list
        NSApplication.shared.setActivationPolicy(.prohibited)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d  h:mm:ss a"

        let now = Date()
        appData.text = dateFormatter.string(from: now)

        let nextSecond = now.addingTimeInterval(1 - fmod(now.timeIntervalSince1970, 1.0))
        let timer = Timer(fire: nextSecond, interval: 1, repeats: true) { [self] _ in
            // Because of jitter, we might consistently get called shortly
            // before the second changes, e.g., hh:mm:ss.99. So round the
            // current time to the nearest second before displaying.
            let now1 = Date()
            let now = Date(timeIntervalSince1970: round(now1.timeIntervalSince1970))
            appData.text = dateFormatter.string(from: now)
        }
        // Allow being off by a frame or two at 60Hz
        timer.tolerance = 2 / 60
        RunLoop.current.add(timer, forMode: .common)
    }

    // window.minSize and window.contentMinSize appear to be no-ops on this window
    func windowWillResize(_: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(width: max(frameSize.width, MIN_WIDTH), height: max(frameSize.height, MIN_HEIGHT))
    }
}
