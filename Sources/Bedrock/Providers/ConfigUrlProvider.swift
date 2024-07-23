import Foundation

struct ConfigURLProvider: URLProvider {
    func getBaseURL() async throws -> String {
        guard let baseUrlString = await ConfigService.shared.getConfig()?.apiUrl
               else {
            throw ServiceErrors.baseUrlNotConfigured
        }
        return baseUrlString
    }
}
