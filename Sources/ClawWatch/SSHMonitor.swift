// Sources/ClawWatch/SSHMonitor.swift
import Foundation

struct OpenClawStatus {
    let crabState: CrabState
    let recentActivity: [ActivityLine]
    let lastUpdated: Date
    let uptimePercent: Double   // 0–100
    let lastPingMs: Int         // -1 = unknown
    let errorsToday: Int
}

struct ActivityLine: Identifiable {
    let id = UUID()
    let age: Date
    let text: String
    let kind: LineKind

    enum LineKind { case ok, warn, error, neutral }
}

final class SSHMonitor: ObservableObject {
    @Published var status: OpenClawStatus = OpenClawStatus(
        crabState: .checking,
        recentActivity: [],
        lastUpdated: .now,
        uptimePercent: 0,
        lastPingMs: -1,
        errorsToday: 0
    )
    @Published var crabState: CrabState = .checking

    private let host = "Macmini.fritz.box"
    private let user = "macmini"
    private var timer: Timer?

    // Rolling stats
    private var pollCount = 0
    private var successCount = 0
    private var errorsTodayCount = 0

    func start() {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func fetch() {
        DispatchQueue.main.async { self.crabState = .checking }
        let fetchStart = Date()

        DispatchQueue.global(qos: .background).async {
            let result = self.run("""
                IS_RUNNING=$(pgrep -f 'openclaw' > /dev/null && echo 'yes' || echo 'no')
                echo "RUNNING:$IS_RUNNING"
                echo "---LOGS---"
                tail -30 ~/.openclaw/logs/gateway.log 2>/dev/null | grep -v '^$'
            """)

            let pingMs = Int(Date().timeIntervalSince(fetchStart) * 1000)
            let lines = result.components(separatedBy: "\n")
            let isRunning = lines.first(where: { $0.hasPrefix("RUNNING:") })?.contains("yes") ?? false
            let connected = !result.isEmpty

            let logStart = lines.firstIndex(of: "---LOGS---").map { $0 + 1 } ?? 0
            let rawLines = Array(lines[logStart...])
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            let activityLines = rawLines.suffix(20).map { self.toActivityLine($0) }

            DispatchQueue.main.async {
                self.pollCount += 1
                if connected { self.successCount += 1 }
                let errCount = activityLines.filter { $0.kind == .error }.count
                self.errorsTodayCount += errCount

                let newState: CrabState
                if !connected        { newState = .offline }
                else if !isRunning   { newState = .error }
                else                 { newState = .active }

                self.crabState = newState
                self.status = OpenClawStatus(
                    crabState: newState,
                    recentActivity: Array(activityLines),
                    lastUpdated: .now,
                    uptimePercent: self.pollCount > 0
                        ? (Double(self.successCount) / Double(self.pollCount)) * 100
                        : 0,
                    lastPingMs: connected ? pingMs : -1,
                    errorsToday: self.errorsTodayCount
                )
            }
        }
    }

    private func run(_ command: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=5",
            "-o", "BatchMode=yes",
            "\(user)@\(host)",
            command
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    private func toActivityLine(_ raw: String) -> ActivityLine {
        let stripped = stripTimestamp(raw)
        let (text, kind) = translate(stripped)
        return ActivityLine(age: .now, text: text, kind: kind)
    }

    private func stripTimestamp(_ line: String) -> String {
        let parts = line.components(separatedBy: " ")
        if parts.count > 1, parts[0].contains("T"), parts[0].contains("+") {
            return parts.dropFirst().joined(separator: " ")
        }
        return line
    }

    private func translate(_ line: String) -> (String, ActivityLine.LineKind) {
        let l = line.lowercased()

        if l.contains("error") || l.contains("err:") || l.contains("failed") || l.contains("crash") {
            return ("✗ \(line)", .error)
        }
        if l.contains("warn") || l.contains("slow") || l.contains("timeout") {
            if let ms = extractMs(line) {
                return ("One request took longer than usual (\(ms)ms)", .warn)
            }
            return ("⚠ \(line)", .warn)
        }
        if l.contains("conn_pool") && l.contains("healthy") {
            return ("Checked connections — all healthy", .ok)
        }
        if l.contains("latency") {
            if let ms = extractMs(line) {
                let kind: ActivityLine.LineKind = ms > 1000 ? .warn : .ok
                return ("Request took \(ms)ms", kind)
            }
        }
        if l.contains("started") || l.contains("restart") {
            return ("OpenClaw started up cleanly", .ok)
        }
        if l.contains("stopped") || l.contains("shutdown") {
            return ("OpenClaw shut down", .warn)
        }
        if l.contains("healthy") || l.contains("ok") || l.contains("success") {
            return ("✓ \(line)", .ok)
        }
        if l.contains("connect") && !l.contains("dis") {
            return ("Connected to gateway", .ok)
        }
        if l.contains("disconnect") {
            return ("Lost connection", .error)
        }
        return (line, .neutral)
    }

    private func extractMs(_ line: String) -> Int? {
        let patterns = [
            #"(\d+)ms"#,
            #"latency[=:](\d+)"#,
        ]
        for pattern in patterns {
            if let r = line.range(of: pattern, options: .regularExpression),
               let numStr = line[r].components(separatedBy: CharacterSet.decimalDigits.inverted).first(where: { !$0.isEmpty }),
               let ms = Int(numStr) {
                return ms
            }
        }
        if let r = line.range(of: #"(\d+\.?\d*)s\b"#, options: .regularExpression) {
            let s = String(line[r].dropLast())
            if let sec = Double(s) { return Int(sec * 1000) }
        }
        return nil
    }
}
