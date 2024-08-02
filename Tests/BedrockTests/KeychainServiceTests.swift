import XCTest
@testable import Bedrock

class KeychainServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        KeychainService.reset()
    }

    override func tearDown() {
        KeychainService.reset()
        super.tearDown()
    }

    func testStoreAndRetrieveTokens() {
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiration = Date()

        XCTAssertNoThrow(try KeychainService.storeTokens(accessToken, refreshToken, expiration))

        XCTAssertNoThrow(try {
            let retrievedAccessToken = try KeychainService.getAccessToken()
            XCTAssertEqual(retrievedAccessToken, accessToken)

            let retrievedRefreshToken = try KeychainService.getRefreshToken()
            XCTAssertEqual(retrievedRefreshToken, refreshToken)
        }())
    }

    func testUpdateTokens() {
        let initialAccessToken = "initial_access_token"
        let initialRefreshToken = "initial_refresh_token"
        let updatedAccessToken = "updated_access_token"
        let updatedRefreshToken = "updated_refresh_token"
        let expiration = Date()

        XCTAssertNoThrow(try KeychainService.storeTokens(initialAccessToken, initialRefreshToken, expiration))
        XCTAssertNoThrow(try KeychainService.storeTokens(updatedAccessToken, updatedRefreshToken, expiration))

        XCTAssertNoThrow(try {
            let retrievedAccessToken = try KeychainService.getAccessToken()
            XCTAssertEqual(retrievedAccessToken, updatedAccessToken)

            let retrievedRefreshToken = try KeychainService.getRefreshToken()
            XCTAssertEqual(retrievedRefreshToken, updatedRefreshToken)
        }())
    }

    func testResetTokens() {
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiration = Date()

        XCTAssertNoThrow(try KeychainService.storeTokens(accessToken, refreshToken, expiration))
        KeychainService.reset()

        XCTAssertThrowsError(try KeychainService.getAccessToken()) { error in
            XCTAssertTrue(error is KeychainWrapperError)
            if let keychainError = error as? KeychainWrapperError {
                XCTAssertEqual(keychainError.type, .itemNotFound)
            }
        }

        XCTAssertThrowsError(try KeychainService.getRefreshToken()) { error in
            XCTAssertTrue(error is KeychainWrapperError)
            if let keychainError = error as? KeychainWrapperError {
                XCTAssertEqual(keychainError.type, .itemNotFound)
            }
        }
    }

    func testEmptyTokenDeletion() {
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiration = Date()

        XCTAssertNoThrow(try KeychainService.storeTokens(accessToken, refreshToken, expiration))
        
        XCTAssertNoThrow(try KeychainService.storeTokens("", "", expiration))

        XCTAssertThrowsError(try KeychainService.getAccessToken()) { error in
            XCTAssertTrue(error is KeychainWrapperError)
            if let keychainError = error as? KeychainWrapperError {
                XCTAssertEqual(keychainError.type, .itemNotFound)
            }
        }

        XCTAssertThrowsError(try KeychainService.getRefreshToken()) { error in
            XCTAssertTrue(error is KeychainWrapperError)
            if let keychainError = error as? KeychainWrapperError {
                XCTAssertEqual(keychainError.type, .itemNotFound)
            }
        }
    }
}
