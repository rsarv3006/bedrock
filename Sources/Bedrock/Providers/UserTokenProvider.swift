import Foundation

public struct UserTokenProvider: TokenProvider {
    public func getToken() async throws -> String {
        return try KeychainService.getAccessToken()
    }
}
