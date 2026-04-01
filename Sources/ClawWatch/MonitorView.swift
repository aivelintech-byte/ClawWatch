import SwiftUI

struct MonitorView: View {
    @ObservedObject var monitor: SSHMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            logView
            Divider()
            footer
        }
        .frame(width: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(monitor.status.isRunning ? Color.green : Color.red)
                .frame(width: 10, height: 10)

            Text(monitor.status.isRunning ? "OpenClaw is running" : "OpenClaw is stopped")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if !monitor.connected {
                Label("No connection", systemImage: "wifi.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Log

    private var logView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(monitor.status.recentActivity.enumerated()), id: \.offset) { i, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(color(for: line))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 1)
                            .id(i)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(height: 300)
            .onChange(of: monitor.status.recentActivity.count) { _ in
                if let last = monitor.status.recentActivity.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }

    private func color(for line: String) -> Color {
        if line.contains("error") || line.contains("err") { return .red }
        if line.contains("warn") { return .orange }
        if line.contains("✓") || line.contains("success") { return .green }
        return .primary
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("Updated \(monitor.status.lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
