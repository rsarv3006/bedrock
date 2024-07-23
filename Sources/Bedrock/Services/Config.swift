import Foundation

public protocol ConfigLoader {
    func loadConfig() async -> Config?
}

public protocol ConfigCacheStrategy {
    func shouldLoadNewConfig(lastLoadedDate: Date?) -> Bool
}

public struct ConfigReturnDto: Codable {
    public let data: ConfigReturnData
}

public struct ConfigReturnData: Codable {
    public let config: Config
}

public struct Config: Codable {
    public let apiUrl: String?
    public let anonToken: String?
    public let minAppVersion: String?

    public init(apiUrl: String, anonToken: String, minAppVersion: String) {
        self.apiUrl = apiUrl
        self.anonToken = anonToken
        self.minAppVersion = minAppVersion
    }
}

public let decoder = JSONDecoder()

public func loadJSON<T: Codable>(filename: String) -> T? {
    guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
        print("JSON file not found")
        return nil
    }

    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let result = try decoder.decode(T.self, from: data)
        return result
    } catch {
        print("Error decoding JSON: \(error)")
        return nil
    }
}

public class ConfigService {
    private var remoteLoader: ConfigLoader
    private var localLoader: ConfigLoader
    private var cacheStrategy: ConfigCacheStrategy

    private var config: Config?
    private var lastLoadedConfig: Date?

    init(remoteLoader: ConfigLoader, localLoader: ConfigLoader, cacheStrategy: ConfigCacheStrategy) {
        self.remoteLoader = remoteLoader
        self.localLoader = localLoader
        self.cacheStrategy = cacheStrategy
    }

    public func getConfig() async -> Config? {
        if let lastLoadedConfig,
           !cacheStrategy.shouldLoadNewConfig(lastLoadedDate: lastLoadedConfig),
           let config
        {
            return config
        }

        let remoteConfig = await remoteLoader.loadConfig()
        if let remoteConfig = remoteConfig {
            lastLoadedConfig = Date()
            config = remoteConfig
            return remoteConfig
        }

        let localConfig = await localLoader.loadConfig()
        if let localConfig = localConfig {
            lastLoadedConfig = Date()
            config = localConfig
            return localConfig
        }

        return config
    }

    public static func resetForTesting(remoteLoader: ConfigLoader,
                                       localLoader: ConfigLoader,
                                       cacheStrategy: ConfigCacheStrategy)
    {
        shared.remoteLoader = remoteLoader
        shared.localLoader = localLoader
        shared.cacheStrategy = cacheStrategy
        shared.config = nil
        shared.lastLoadedConfig = nil
    }
}

public extension ConfigService {
    static let shared = ConfigService(
        remoteLoader: RemoteConfigLoader(),
        localLoader: LocalConfigLoader(),
        cacheStrategy: TimeBabasedCacheStrategy()
    )
}

public class TimeBasedCacheStrategy: ConfigCacheStrategy {
    let cacheTimeInSeconds: Double

    public init(cacheTimeInSeconds: Double = 300) {
        self.cacheTimeInSeconds = cacheTimeInSeconds
    }

    public func shouldLoadNewConfig(lastLoadedDate: Date?) -> Bool {
        guard let lastLoadedDate = lastLoadedDate else { return true }
        return Date().timeIntervalSince(lastLoadedDate) > cacheTimeInSeconds
    }
}

public class RemoteConfigLoader: ConfigLoader {
    public init() {}

    public func loadConfig() async -> Config? {
        let configApiUrl = PlistHelpers.getKeyValueFromPlist(plistFileName: "Config", key: "ConfigApiUrl")
        let configApiToken = PlistHelpers.getKeyValueFromPlist(plistFileName: "Config", key: "ConfigApiToken")
        guard let configApiUrl,
              let configApiToken,
              let url = URL(string: "\(configApiUrl)/api/v1/config/basketbuddy")
        else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(configApiToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                let configReturn = try decoder.decode(ConfigReturnDto.self, from: data)
                let config = configReturn.data.config
                return config

            } else {
                let serverError = try decoder.decode(ServerErrorMessage.self, from: data)
                throw ServiceErrors.custom(message: serverError.error)
            }
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

public class LocalConfigLoader: ConfigLoader {
    public init() {}

    public func loadConfig() async -> Config? {
        return loadJSON(filename: "DefaultConfig")
    }
}

public class TimeBabasedCacheStrategy: ConfigCacheStrategy {
    let cacheTimeInSeconds: Double

    init(cacheTimeInSeconds: Double = 300) { // 5 minutes default
        self.cacheTimeInSeconds = cacheTimeInSeconds
    }

    public func shouldLoadNewConfig(lastLoadedDate: Date?) -> Bool {
        guard let lastLoadedDate = lastLoadedDate else { return true }
        return Date().timeIntervalSince(lastLoadedDate) > cacheTimeInSeconds
    }
}
