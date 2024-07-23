import Foundation

public struct ServerErrorMessage: Codable {
    public let error: String
    
    public init(error: String) {
        self.error = error
    }
}
