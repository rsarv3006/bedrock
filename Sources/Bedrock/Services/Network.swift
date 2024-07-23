import Foundation
import Combine

public struct Networking {
    private let urlProvider: URLProvider
    private let dynamicTokenProvider: DynamicTokenProvider

    public init(urlProvider: URLProvider, dynamicTokenProvider: DynamicTokenProvider) {
        self.urlProvider = urlProvider
        self.dynamicTokenProvider = dynamicTokenProvider
    }
    
    public func updateAuthState(_ newState: AuthState) {
        dynamicTokenProvider.updateAuthState(newState)
    }
    
    private func apiCall(httpMethod: HttpMethod, url: URL, body: Data? = nil) async throws -> (Data, URLResponse) {
        let token = try await dynamicTokenProvider.getToken()
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        if let body = body {
            request.httpBody = body
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let response = try await URLSession.shared.data(for: request)
        
        return response
    }
    
    public func get(url: URL, body: Data? = nil) async throws -> (Data, URLResponse) {
        try await apiCall(httpMethod: .get, url: url, body: body)
    }
    
    public func post(url: URL, body: Data? = nil) async throws -> (Data, URLResponse) {
        try await apiCall(httpMethod: .post, url: url, body: body)
    }
    
    public func put(url: URL, body: Data? = nil) async throws -> (Data, URLResponse) {
        try await apiCall(httpMethod: .put, url: url, body: body)
    }
    
    public func patch(url: URL, body: Data? = nil) async throws -> (Data, URLResponse) {
        try await apiCall(httpMethod: .patch, url: url, body: body)
    }
    
    public func delete(url: URL, body: Data? = nil) async throws -> (Data, URLResponse) {
        try await apiCall(httpMethod: .delete, url: url, body: body)
    }
    
    public func createUrl(endPoint: String) async throws -> URL {
        let baseUrl = try await urlProvider.getBaseURL()
        
        let url = URL(string: "\(baseUrl)\(endPoint)")
        
        guard let url = url else {
            throw ServiceErrors.unknownUrl
        }
        
        return url
    }
}

extension Networking {
    public static func createDefault() -> Networking {
        let configTokenProvider = ConfigTokenProvider()
        let userTokenProvider = UserTokenProvider()
        let urlProvider = ConfigURLProvider()

        let dynamicTokenProvider = DynamicTokenProvider(
            configTokenProvider: configTokenProvider,
            userTokenProvider: userTokenProvider
        )
        
        return Networking(urlProvider: urlProvider, dynamicTokenProvider: dynamicTokenProvider)
    }
}
