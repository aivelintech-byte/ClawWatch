// Sources/ClawWatch/CrabState.swift
enum CrabState {
    case active    // server up, polling normally — claws clacking
    case checking  // mid-SSH fetch — spinning
    case offline   // SSH failed — grey and still
    case error     // OpenClaw crashed or errors — raised claws, red glow

    var symbolName: String {
        switch self {
        case .active:   return "pawprint.fill"
        case .checking: return "arrow.triangle.2.circlepath"
        case .offline:  return "pawprint"
        case .error:    return "exclamationmark.triangle.fill"
        }
    }
}
