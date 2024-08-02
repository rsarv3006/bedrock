import XCTest
@testable import Bedrock

// Define a concrete Config type for testing
struct TestConfig: GenericConfig {
    let apiUrl: String
    let anonToken: String
    let minAppVersion: String
}

class MockConfigLoader<T: GenericConfig>: ConfigLoader {
    var configToReturn: T?
    var loadConfigCalled = false
    var loadConfigCallCount = 0
    
    func loadConfig() async -> T? {
        loadConfigCalled = true
        loadConfigCallCount += 1
        return configToReturn
    }
}

class MockCacheStrategy: ConfigCacheStrategy {
    var shouldLoadNewConfigResult = false
    
    func shouldLoadNewConfig(lastLoadedDate: Date?) -> Bool {
        return shouldLoadNewConfigResult
    }
}

class ConfigServiceTests: XCTestCase {
    
    var configService: ConfigService<TestConfig>!
    var mockRemoteLoader: MockConfigLoader<TestConfig>!
    var mockLocalLoader: MockConfigLoader<TestConfig>!
    var mockCacheStrategy: MockCacheStrategy!
    
    override func setUp() {
        super.setUp()
        mockRemoteLoader = MockConfigLoader<TestConfig>()
        mockLocalLoader = MockConfigLoader<TestConfig>()
        mockCacheStrategy = MockCacheStrategy()
        
        configService = ConfigService<TestConfig>(
            remoteLoader: mockRemoteLoader,
            localLoader: mockLocalLoader,
            cacheStrategy: mockCacheStrategy
        )
    }
    
    override func tearDown() {
        configService = nil
        mockRemoteLoader = nil
        mockLocalLoader = nil
        mockCacheStrategy = nil
        super.tearDown()
    }
    
    func testRemoteConfigLoading() async {
        mockRemoteLoader.configToReturn = TestConfig(apiUrl: "test", anonToken: "test", minAppVersion: "1.0")
        mockCacheStrategy.shouldLoadNewConfigResult = true
        
        let config = await configService.getConfig()
        
        XCTAssertNotNil(config)
        XCTAssertTrue(mockRemoteLoader.loadConfigCalled)
        XCTAssertFalse(mockLocalLoader.loadConfigCalled)
        XCTAssertEqual(config?.apiUrl, "test")
    }
    
    func testLocalConfigFallback() async {
        mockRemoteLoader.configToReturn = nil
        mockLocalLoader.configToReturn = TestConfig(apiUrl: "local", anonToken: "local", minAppVersion: "1.0")
        mockCacheStrategy.shouldLoadNewConfigResult = true
        
        let config = await configService.getConfig()
        
        XCTAssertNotNil(config)
        XCTAssertTrue(mockRemoteLoader.loadConfigCalled)
        XCTAssertTrue(mockLocalLoader.loadConfigCalled)
        XCTAssertEqual(config?.apiUrl, "local")
    }
    
    func testCaching() async {
        mockRemoteLoader.configToReturn = TestConfig(apiUrl: "test", anonToken: "test", minAppVersion: "1.0")
        mockCacheStrategy.shouldLoadNewConfigResult = false
        
        _ = await configService.getConfig()  // First call should use remote loader
        _ = await configService.getConfig()  // Second call should use cached config
        
        XCTAssertTrue(mockRemoteLoader.loadConfigCalled)
        XCTAssertFalse(mockLocalLoader.loadConfigCalled)
        XCTAssertEqual(mockRemoteLoader.loadConfigCallCount, 1)
    }
}
