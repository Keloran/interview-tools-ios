import SwiftUI
import FlagsGG

// EnvironmentKey to hold a shared Flags client/agent
private struct FlagsAgentKey: EnvironmentKey {
    static let defaultValue: FlagsClient? = nil
}

public extension EnvironmentValues {
    var flagsAgent: FlagsClient? {
        get { self[FlagsAgentKey.self] }
        set { self[FlagsAgentKey.self] = newValue }
    }
}

public extension View {
    /// Inject a shared Flags client/agent into the environment
    func flagsAgent(_ agent: FlagsClient) -> some View {
        environment(\.flagsAgent, agent)
    }
}
