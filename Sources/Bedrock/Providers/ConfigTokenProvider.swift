import Foundation

struct ConfigTokenProvider: TokenProvider {
    func getToken() async throws -> String {
        guard let token = await ConfigService.shared.getConfig()?.anonToken else {
            throw ServiceErrors.custom(message: "Token not found in config.")
        }
        return token
    }
}
