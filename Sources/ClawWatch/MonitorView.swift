// Sources/ClawWatch/MonitorView.swift
import SwiftUI

struct MonitorView: View {
    @ObservedObject var monitor: SSHMonitor
    @State private var clawToggle = false
    @State private var legToggle = false
    @State private var bubbleText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            crabHeader
            Divider()
            statsStrip
            Divider()
            feedView
            Divider()
            footer
        }
        .frame(width: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            clawToggle = true
            legToggle = true
            bubbleText = liveBubbleMessage
        }
        .onChange(of: monitor.status.recentActivity.count) { _ in
            bubbleText = liveBubbleMessage
        }
        .onChange(of: monitor.crabState) { _ in
            bubbleText = liveBubbleMessage
        }
    }

    // MARK: - Crab Header

    private var crabHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            crabView
            speechBubble
            Spacer()
            statusDot
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        HStack(spacing: 0) {
            BubbleTail()
                .fill(bubbleBgColor)
                .frame(width: 10, height: 12)
                .offset(x: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(bubbleText.isEmpty ? liveBubbleMessage : bubbleText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(bubbleTextColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(stateLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(bubbleTextColor.opacity(0.7))
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bubbleBgColor)
            )
        }
        .animation(.easeInOut(duration: 0.3), value: bubbleText)
    }

    private var stateLabel: String {
        switch monitor.crabState {
        case .active:   return "running · mac mini"
        case .checking: return "checking · every 5s"
        case .offline:  return "offline · retrying…"
        case .error:    return "error · needs attention"
        }
    }

    private var liveBubbleMessage: String {
        switch monitor.crabState {
        case .checking:
            return "SSH-ing into mac mini…"
        case .offline:
            return "Can't reach the server. Is the Mac mini on?"
        case .error:
            if let last = monitor.status.recentActivity.last(where: { $0.kind == .error }) {
                return last.text
            }
            return "OpenClaw stopped. Might need a restart."
        case .active:
            if let last = monitor.status.recentActivity.last {
                return last.text
            }
            return "All good — claws are clacking!"
        }
    }

    private var bubbleBgColor: Color {
        switch monitor.crabState {
        case .active:   return Color.green.opacity(0.15)
        case .checking: return Color.blue.opacity(0.15)
        case .offline:  return Color.gray.opacity(0.15)
        case .error:    return Color.red.opacity(0.15)
        }
    }

    private var bubbleTextColor: Color {
        switch monitor.crabState {
        case .active:   return .green
        case .checking: return .blue
        case .offline:  return .secondary
        case .error:    return .red
        }
    }

    // MARK: - Crab

    private var crabView: some View {
        ZStack {
            switch monitor.crabState {
            case .active:
                VStack(spacing: -4) {
                    // Claws wiggling
                    HStack(spacing: 0) {
                        Text("🦾")
                            .font(.system(size: 14))
                            .rotationEffect(.degrees(clawToggle ? -30 : -10), anchor: .bottomTrailing)
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: clawToggle)
                        Spacer().frame(width: 20)
                        Text("🦾")
                            .font(.system(size: 14))
                            .scaleEffect(x: -1)
                            .rotationEffect(.degrees(clawToggle ? 30 : 10), anchor: .bottomLeading)
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(0.1), value: clawToggle)
                    }
                    Text("🦀")
                        .font(.system(size: 44))
                        .offset(y: clawToggle ? -2 : 2)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: clawToggle)
                }

            case .checking:
                Text("🦀")
                    .font(.system(size: 44))
                    .rotationEffect(.degrees(clawToggle ? 18 : -18))
                    .offset(x: clawToggle ? 3 : -3)
                    .animation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: clawToggle)

            case .offline:
                Text("🦀")
                    .font(.system(size: 44))
                    .grayscale(1)
                    .opacity(clawToggle ? 0.55 : 0.2)
                    .scaleEffect(0.9)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: clawToggle)

            case .error:
                ZStack {
                    // Red glow ring
                    Circle()
                        .fill(Color.red.opacity(clawToggle ? 0.25 : 0.05))
                        .frame(width: 60, height: 60)
                        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: clawToggle)
                    Text("🦀")
                        .font(.system(size: 44))
                        .colorMultiply(.red)
                        .scaleEffect(clawToggle ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: clawToggle)
                }
            }
        }
        .frame(width: 64, height: 64)
    }

    // MARK: - Status dot

    private var statusDot: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
                .shadow(color: dotColor.opacity(0.9), radius: clawToggle ? 6 : 2)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: clawToggle)
        }
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
            Divider().frame(height: 32)
            statCell(
                value: monitor.status.lastPingMs >= 0 ? "\(monitor.status.lastPingMs)ms" : "—",
                label: "last ping"
            )
            Divider().frame(height: 32)
            statCell(
                value: "\(monitor.status.errorsToday)",
                label: "errors today"
            )
        }
        .padding(.vertical, 10)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .monospaced))
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
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(monitor.status.recentActivity) { line in
                        feedRow(line)
                            .id(line.id)
                    }
                }
                .padding(.vertical, 8)
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
        HStack(alignment: .top, spacing: 10) {
            Text(relativeTime(line.age))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 58, alignment: .trailing)
            Text(line.text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(feedColor(line.kind))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

// MARK: - Bubble tail shape

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.midY - 6))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 6))
        p.closeSubpath()
        return p
    }
}
