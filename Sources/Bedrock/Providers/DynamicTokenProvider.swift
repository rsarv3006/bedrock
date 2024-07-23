import Foundation

public class DynamicTokenProvider: TokenProvider {
    private let configTokenProvider: TokenProvider
    private let userTokenProvider: TokenProvider
    private var currentAuthState: AuthState = .anonymous

    public init(configTokenProvider: TokenProvider, userTokenProvider: TokenProvider) {
        self.configTokenProvider = configTokenProvider
        self.userTokenProvider = userTokenProvider
    }

    public func getToken() async throws -> String {
        switch currentAuthState {
        case .anonymous:
            return try await configTokenProvider.getToken()
        case .authenticated:
            return try await userTokenProvider.getToken()
        }
    }

    public func updateAuthState(_ newState: AuthState) {
        currentAuthState = newState
    }
}


