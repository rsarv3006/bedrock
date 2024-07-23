import XCTest

import Bedrock

class MockConfigLoader: ConfigLoader {
    var configToReturn: Config?
    var loadConfigCalled = false
    var loadConfigCallCount = 0
    
    func loadConfig() async -> Config? {
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
    
    override func tearDown() {
        // Reset to default state after each test
        ConfigService.resetForTesting(remoteLoader: RemoteConfigLoader(),
                                      localLoader: LocalConfigLoader(),
                                      cacheStrategy: TimeBasedCacheStrategy())
    }
    
    func testRemoteConfigLoading() async {
        let mockRemoteLoader = MockConfigLoader()
        let mockLocalLoader = MockConfigLoader()
        let mockCacheStrategy = MockCacheStrategy()
        
        mockRemoteLoader.configToReturn = Config(apiUrl: "test", anonToken: "test", minAppVersion: "1.0")
        mockCacheStrategy.shouldLoadNewConfigResult = true
        
        ConfigService.resetForTesting(remoteLoader: mockRemoteLoader,
                                      localLoader: mockLocalLoader,
                                      cacheStrategy: mockCacheStrategy)
        
        let config = await ConfigService.shared.getConfig()
        
        XCTAssertNotNil(config)
        XCTAssertTrue(mockRemoteLoader.loadConfigCalled)
        XCTAssertFalse(mockLocalLoader.loadConfigCalled)
    }
    
    func testLocalConfigFallback() async {
        let mockRemoteLoader = MockConfigLoader()
        let mockLocalLoader = MockConfigLoader()
        let mockCacheStrategy = MockCacheStrategy()
        
        mockRemoteLoader.configToReturn = nil
        mockLocalLoader.configToReturn = Config(apiUrl: "local", anonToken: "local", minAppVersion: "1.0")
        mockCacheStrategy.shouldLoadNewConfigResult = true
        
        ConfigService.resetForTesting(remoteLoader: mockRemoteLoader,
                                      localLoader: mockLocalLoader,
                                      cacheStrategy: mockCacheStrategy)
        
        let config = await ConfigService.shared.getConfig()
        
        XCTAssertNotNil(config)
        XCTAssertTrue(mockRemoteLoader.loadConfigCalled)
        XCTAssertTrue(mockLocalLoader.loadConfigCalled)
        XCTAssertEqual(config?.apiUrl, "local")
    }
    
    func testCaching() async {
        let mockRemoteLoader = MockConfigLoader()
        let mockLocalLoader = MockConfigLoader()
        let mockCacheStrategy = MockCacheStrategy()
        
        mockRemoteLoader.configToReturn = Config(apiUrl: "test", anonToken: "test", minAppVersion: "1.0")
        mockCacheStrategy.shouldLoadNewConfigResult = false
        
        ConfigService.resetForTesting(remoteLoader: mockRemoteLoader,
                                      localLoader: mockLocalLoader,
                                      cacheStrategy: mockCacheStrategy)
        
        _ = await ConfigService.shared.getConfig()  // First call should use remote loader
        _ = await ConfigService.shared.getConfig()  // Second call should use cached config
        
        XCTAssertTrue(mockRemoteLoader.loadConfigCalled)
        XCTAssertFalse(mockLocalLoader.loadConfigCalled)
        XCTAssertEqual(mockRemoteLoader.loadConfigCallCount, 1)  // Changed this line
    }
}
