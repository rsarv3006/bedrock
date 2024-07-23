import XCTest
@testable import Bedrock

class NetworkingTests: XCTestCase {
    var networking: Networking!
    var mockURLProvider: MockURLProvider!
    var mockDynamicTokenProvider: MockDynamicTokenProvider!
    
    override func setUpWithError() throws {
        mockURLProvider = MockURLProvider()
        mockDynamicTokenProvider = MockDynamicTokenProvider()
        mockDynamicTokenProvider.token = "test_token"
        
        networking = Networking(urlProvider: mockURLProvider, dynamicTokenProvider: mockDynamicTokenProvider)
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    override func tearDownWithError() throws {
        networking = nil
        mockURLProvider = nil
        mockDynamicTokenProvider = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
    }
    
    func testUpdateAuthState() {
        networking.updateAuthState(.authenticated)
        XCTAssertEqual(mockDynamicTokenProvider.currentAuthState, .authenticated)
    }
    
    func testCreateUrl() async throws {
        mockURLProvider.baseURL = "https://api.example.com"
        let url = try await networking.createUrl(endPoint: "/users")
        XCTAssertEqual(url.absoluteString, "https://api.example.com/users")
    }
    
    func testApiCallSetsCorrectHeaders() async throws {
        let expectation = XCTestExpectation(description: "API call completed")
        
        mockDynamicTokenProvider.token = "test_token"
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test_token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            expectation.fulfill()
            return (HTTPURLResponse(), Data())
        }
        
        _ = try await networking.get(url: URL(string: "https://api.example.com")!)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testGetRequest() async throws {
        let expectation = XCTestExpectation(description: "GET request completed")
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
            return (HTTPURLResponse(), Data())
        }
        
        _ = try await networking.get(url: URL(string: "https://api.example.com")!)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testPostRequest() async throws {
        let expectation = XCTestExpectation(description: "POST request completed")
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            expectation.fulfill()
            return (HTTPURLResponse(), Data())
        }
        
        _ = try await networking.post(url: URL(string: "https://api.example.com")!, body: "{}".data(using: .utf8))
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testPutRequest() async throws {
        let expectation = XCTestExpectation(description: "PUT request completed")
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            expectation.fulfill()
            return (HTTPURLResponse(), Data())
        }
        
        _ = try await networking.put(url: URL(string: "https://api.example.com")!, body: "{}".data(using: .utf8))
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testPatchRequest() async throws {
        let expectation = XCTestExpectation(description: "PATCH request completed")
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            expectation.fulfill()
            return (HTTPURLResponse(), Data())
        }
        
        _ = try await networking.patch(url: URL(string: "https://api.example.com")!, body: "{}".data(using: .utf8))
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testDeleteRequest() async throws {
        let expectation = XCTestExpectation(description: "DELETE request completed")
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            expectation.fulfill()
            return (HTTPURLResponse(), Data())
        }
        
        _ = try await networking.delete(url: URL(string: "https://api.example.com")!)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}


// MARK: - Mock Objects
class MockURLProvider: URLProvider {
    var baseURL: String?
    func getBaseURL() async throws -> String {
        guard let baseURL = baseURL else {
            throw NSError(domain: "MockURLProvider", code: 0, userInfo: [NSLocalizedDescriptionKey: "Base URL not set"])
        }
        return baseURL
    }
}

class MockDynamicTokenProvider: DynamicTokenProvider {
    var token: String?
    var currentAuthState: AuthState = .anonymous

    init() {
        super.init(configTokenProvider: MockTokenProvider(), userTokenProvider: MockTokenProvider())
    }

    override func getToken() async throws -> String {
        guard let token = token else {
            throw NSError(domain: "MockDynamicTokenProvider", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token not set"])
        }
        return token
    }

    override func updateAuthState(_ newState: AuthState) {
        currentAuthState = newState
    }
}

class MockTokenProvider: TokenProvider {
    func getToken() async throws -> String {
        return "mock_token"
    }
}

class MockURLSession: URLSession {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void

    var data: Data?
    var response: URLResponse?
    var error: Error?

    override func dataTask(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        return MockURLSessionDataTask {
            completionHandler(self.data, self.response, self.error)
        }
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
