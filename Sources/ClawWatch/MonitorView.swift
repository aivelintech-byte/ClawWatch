// Sources/ClawWatch/MonitorView.swift
import SwiftUI

struct MonitorView: View {
    @ObservedObject var monitor: SSHMonitor
    @State private var clawToggle = false
    @State private var bubbleMessageIndex = 0
    @State private var bubbleVisible = true

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
        .frame(width: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            clawToggle = true
            startBubbleRotation()
        }
        .onChange(of: monitor.crabState) { _ in
            bubbleMessageIndex = 0
            startBubbleRotation()
        }
    }

    // MARK: - Crab Header with Speech Bubble

    private var crabHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            // Crab
            crabView
                .padding(.top, 8)

            // Speech bubble
            VStack(alignment: .leading, spacing: 0) {
                speechBubble
                    .padding(.top, 6)
                Text("Checking every 5s · mac mini")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Spacer()
            statusDot
                .padding(.top, 14)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Speech Bubble

    private var speechBubble: some View {
        HStack(alignment: .center, spacing: 0) {
            // Tail
            BubbleTail()
                .fill(bubbleBgColor)
                .frame(width: 10, height: 10)
                .offset(x: 1)

            Text(currentBubbleMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(bubbleTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bubbleBgColor)
                )
        }
        .opacity(bubbleVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: bubbleVisible)
    }

    private var bubbleBgColor: Color {
        switch monitor.crabState {
        case .active:   return Color.green.opacity(0.18)
        case .checking: return Color.blue.opacity(0.18)
        case .offline:  return Color.gray.opacity(0.18)
        case .error:    return Color.red.opacity(0.18)
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

    private var currentBubbleMessage: String {
        let messages = bubbleMessages
        return messages[bubbleMessageIndex % messages.count]
    }

    private var bubbleMessages: [String] {
        switch monitor.crabState {
        case .active:
            let last = monitor.status.recentActivity.last(where: { $0.kind == .ok })?.text
            return [
                "All claws working! 🦀",
                "Everything looks healthy.",
                "Connections are solid.",
                last.map { "Latest: \($0)" } ?? "Polling away…",
                "Uptime \(String(format: "%.0f", monitor.status.uptimePercent))% — not bad!",
            ]
        case .checking:
            return [
                "Hang on, checking…",
                "SSH-ing in…",
                "Peeking at the logs…",
                "One moment…",
            ]
        case .offline:
            return [
                "Can't reach the server!",
                "SSH connection failed.",
                "Is the Mac mini awake?",
                "Waiting to reconnect…",
            ]
        case .error:
            let errCount = monitor.status.errorsToday
            return [
                "OpenClaw has stopped! 😱",
                errCount > 0 ? "\(errCount) error(s) found today." : "Something went wrong.",
                "The process isn't running.",
                "Might need a restart!",
            ]
        }
    }

    private func startBubbleRotation() {
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { timer in
            guard monitor.crabState == monitor.crabState else { timer.invalidate(); return }
            withAnimation { bubbleVisible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bubbleMessageIndex += 1
                withAnimation { bubbleVisible = true }
            }
        }
    }

    // MARK: - Crab

    private var crabView: some View {
        ZStack {
            switch monitor.crabState {
            case .active:
                Text("🦀")
                    .font(.system(size: 36))
                    .offset(y: clawToggle ? -3 : 3)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: clawToggle)

            case .checking:
                Text("🦀")
                    .font(.system(size: 36))
                    .rotationEffect(.degrees(clawToggle ? 20 : -20))
                    .animation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: clawToggle)

            case .offline:
                Text("🦀")
                    .font(.system(size: 36))
                    .grayscale(1)
                    .opacity(clawToggle ? 0.5 : 0.25)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: clawToggle)

            case .error:
                Text("🦀")
                    .font(.system(size: 36))
                    .colorMultiply(.red)
                    .shadow(color: .red.opacity(0.9), radius: clawToggle ? 8 : 2)
                    .scaleEffect(clawToggle ? 1.12 : 0.95)
                    .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: clawToggle)
            }
        }
        .frame(width: 48, height: 48)
    }

    // MARK: - Status dot

    private var statusDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 10, height: 10)
            .shadow(color: dotColor.opacity(0.8), radius: 4)
            .opacity(clawToggle ? 1.0 : 0.3)
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
            .frame(height: 200)
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
}

// MARK: - Bubble tail shape

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.midY - 5))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 5))
        p.closeSubpath()
        return p
    }
}
