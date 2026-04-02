// Sources/ClawWatch/MonitorView.swift
import SwiftUI

struct MonitorView: View {
    @ObservedObject var monitor: SSHMonitor
    @State private var clawToggle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            statsStrip
            Divider()
            feedView
            Divider()
            footer
        }
        .frame(width: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startClawTimer()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            crabView
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 13, weight: .semibold))
                Text("Checking every 5s · mac mini")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusDot
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var headerTitle: String {
        switch monitor.crabState {
        case .active:   return "OpenClaw is running"
        case .checking: return "Checking…"
        case .offline:  return "Can't reach server"
        case .error:    return "OpenClaw stopped"
        }
    }

    // MARK: - Crab

    private var crabView: some View {
        ZStack {
            switch monitor.crabState {
            case .active:
                activeClawView
            case .checking:
                Text("🦀")
                    .font(.system(size: 34))
                    .rotationEffect(.degrees(clawToggle ? 15 : -15))
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: clawToggle)
            case .offline:
                Text("🦀")
                    .font(.system(size: 34))
                    .grayscale(1)
                    .opacity(0.45)
            case .error:
                Text("🦀")
                    .font(.system(size: 34))
                    .colorMultiply(.red)
                    .shadow(color: .red.opacity(0.8), radius: 6)
                    .scaleEffect(clawToggle ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: clawToggle)
            }
        }
        .frame(width: 44, height: 44)
    }

    private var activeClawView: some View {
        ZStack {
            Text("🦀")
                .font(.system(size: 34))
                .offset(y: clawToggle ? -2 : 2)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: clawToggle)
        }
    }

    // MARK: - Status dot

    private var statusDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 10, height: 10)
            .shadow(color: dotColor.opacity(0.8), radius: 4)
            .opacity(clawToggle ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: clawToggle)
    }

    private var dotColor: Color {
        switch monitor.crabState {
        case .active:   return .green
        case .checking: return .blue
        case .offline:  return .gray
        case .error:    return .red
        }
    }

    // MARK: - Stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statCell(
                value: String(format: "%.1f%%", monitor.status.uptimePercent),
                label: "uptime"
            )
            Divider().frame(height: 28)
            statCell(
                value: monitor.status.lastPingMs >= 0 ? "\(monitor.status.lastPingMs)ms" : "—",
                label: "last ping"
            )
            Divider().frame(height: 28)
            statCell(
                value: "\(monitor.status.errorsToday)",
                label: "errors today"
            )
        }
        .padding(.vertical, 8)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Feed

    private var feedView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(monitor.status.recentActivity) { line in
                        feedRow(line)
                            .id(line.id)
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(height: 220)
            .onChange(of: monitor.status.recentActivity.count) { _ in
                if let last = monitor.status.recentActivity.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func feedRow(_ line: ActivityLine) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(relativeTime(line.age))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 56, alignment: .trailing)
            Text(line.text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(feedColor(line.kind))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
    }

    private func feedColor(_ kind: ActivityLine.LineKind) -> Color {
        switch kind {
        case .ok:      return .green
        case .warn:    return .yellow
        case .error:   return .red
        case .neutral: return .primary
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 5  { return "now" }
        if secs < 60 { return "\(secs)s ago" }
        let mins = secs / 60
        if mins < 60 { return "\(mins)m ago" }
        return "\(mins / 60)h ago"
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

    // MARK: - Helpers

    private func startClawTimer() {
        clawToggle = true
    }
}
