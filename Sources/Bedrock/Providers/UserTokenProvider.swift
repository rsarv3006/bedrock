import Foundation

public struct UserTokenProvider: TokenProvider {
    public init() {}
    
    public func getToken() async throws -> String {
        return try KeychainService.getAccessToken()
    }
}
