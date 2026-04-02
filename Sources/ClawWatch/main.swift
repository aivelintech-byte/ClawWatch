import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let monitor = SSHMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "OpenClaw")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 480, height: 420)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MonitorView(monitor: monitor))
        self.popover = popover

        monitor.start()
        updateIcon()

        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateIcon() {
        let symbolName = monitor.crabState.symbolName
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ClawWatch")
        image?.isTemplate = true
        statusItem?.button?.image = image

        switch monitor.crabState {
        case .active:   statusItem?.button?.contentTintColor = nil
        case .checking: statusItem?.button?.contentTintColor = .systemBlue
        case .offline:  statusItem?.button?.contentTintColor = .systemGray
        case .error:    statusItem?.button?.contentTintColor = .systemRed
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
