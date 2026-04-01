import Foundation

struct OpenClawStatus {
    let isRunning: Bool
    let recentActivity: [String]
    let lastUpdated: Date
}

final class SSHMonitor: ObservableObject {
    @Published var status: OpenClawStatus = OpenClawStatus(isRunning: false, recentActivity: [], lastUpdated: .now)
    @Published var connected: Bool = false

    private let host = "Macmini.fritz.box"
    private let user = "macmini"
    private var timer: Timer?

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
        DispatchQueue.global(qos: .background).async {
            let result = self.run("""
                IS_RUNNING=$(pgrep -f 'openclaw' > /dev/null && echo 'yes' || echo 'no')
                echo "RUNNING:$IS_RUNNING"
                echo "---LOGS---"
                tail -30 ~/.openclaw/logs/gateway.log 2>/dev/null | grep -v '^$'
            """)

            let lines = result.components(separatedBy: "\n")
            let isRunning = lines.first(where: { $0.hasPrefix("RUNNING:") })?.contains("yes") ?? false
            let logStart = lines.firstIndex(of: "---LOGS---").map { $0 + 1 } ?? 0
            let logLines = Array(lines[logStart...])
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { self.formatLine($0) }
                .suffix(20)

            DispatchQueue.main.async {
                self.connected = !result.isEmpty
                self.status = OpenClawStatus(
                    isRunning: isRunning,
                    recentActivity: Array(logLines),
                    lastUpdated: .now
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

    private func formatLine(_ line: String) -> String {
        // Strip timestamp prefix (ISO8601) for cleaner display
        let parts = line.components(separatedBy: " ")
        if parts.count > 1, parts[0].contains("T"), parts[0].contains("+") {
            return parts.dropFirst().joined(separator: " ")
        }
        return line
    }
}
