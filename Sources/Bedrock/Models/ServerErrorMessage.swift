import Foundation

public struct ServerErrorMessage: Codable {
    let error: String
    
    public init(error: String) {
        self.error = error
    }
}
