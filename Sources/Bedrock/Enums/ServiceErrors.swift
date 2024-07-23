import Foundation

enum ServiceErrors: Error, LocalizedError {
    case custom(message: String)
    case unknownUrl
    case dataSerializationFailed(dataObjectName: String)
    case baseUrlNotConfigured

    public var errorDescription: String? {
        switch self {
        case .custom(let message):
            return NSLocalizedString(message, comment: "An unexpected error occurred.")
        case .unknownUrl:
            return NSLocalizedString("An error occurred connecting.", comment: "Unable to connect.")
        case .dataSerializationFailed(let dataObjectName):
            return NSLocalizedString(
                "An error occurred parsing serialized data. Unable to serialize \(dataObjectName)",
                comment: "")
        case .baseUrlNotConfigured:
            return NSLocalizedString("An unexpected error occurred.", comment: "Base URL not configured.")
        }
    }
}
