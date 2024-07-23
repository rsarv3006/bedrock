import Foundation

struct UserTokenProvider: TokenProvider {
    func getToken() async throws -> String {
        return try KeychainService.getAccessToken()
    }
}
