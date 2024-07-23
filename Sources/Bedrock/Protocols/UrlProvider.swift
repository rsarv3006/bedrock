import Foundation

public protocol URLProvider {
    func getBaseURL() async throws -> String
}
